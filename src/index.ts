#!/usr/bin/env node
import { Server } from "@modelcontextprotocol/sdk/server/index.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import {
  ListToolsRequestSchema,
  CallToolRequestSchema,
} from "@modelcontextprotocol/sdk/types.js";
import http from "node:http";
import crypto from "node:crypto";
import { Duplex } from "node:stream";

const WS_MAGIC = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";
const BASE_PORT = parseInt(process.env.GODOT_MCP_PORT ?? "6505", 10);
const ALL_PORTS = Array.from({ length: 10 }, (_, i) => BASE_PORT + i);
const REQUEST_TIMEOUT = 30_000;

function wsAccept(key: string): string {
  return crypto.createHash("sha1").update(key + WS_MAGIC).digest("base64");
}

function wsSend(socket: Duplex, text: string): void {
  const buf = Buffer.from(text, "utf8");
  const h = Buffer.alloc(4);
  h[0] = 0x81; h[1] = 126; h.writeUInt16BE(buf.length, 2);
  socket.write(Buffer.concat([h, buf]));
}

interface Pending {
  resolve: (v: unknown) => void;
  reject: (e: unknown) => void;
  timer: NodeJS.Timeout;
}

function decodeFrame(buf: Buffer): { opcode: number; payload: Buffer; total: number } | null {
  if (buf.length < 2) return null;
  const opcode = buf[0] & 0x0f;
  const masked = (buf[1] & 0x80) !== 0;
  let len = buf[1] & 0x7f;
  let off = 2;
  if (len === 126) { if (buf.length < 4) return null; len = buf.readUInt16BE(2); off = 4; }
  if (len === 127) { if (buf.length < 10) return null; len = Number(buf.readBigUInt64BE(2)); off = 10; }
  const mLen = masked ? 4 : 0;
  if (buf.length < off + mLen + len) return null;
  const mask = masked ? buf.subarray(off, off + 4) : null; off += mLen;
  let payload = Buffer.from(buf.subarray(off, off + len));
  if (mask) for (let i = 0; i < payload.length; i++) payload[i] ^= mask[i % 4];
  return { opcode, payload, total: off + len };
}

class GodotBridge {
  private servers = new Set<http.Server>();
  private peers = new Map<number, Duplex>();
  private bufs = new Map<Duplex, Buffer>();
  private pending = new Map<number, Pending>();
  private nextId = 1;

  start(): void {
    for (const port of ALL_PORTS) {
      const srv = http.createServer();
      srv.on("upgrade", (req, socket) => {
        const key = req.headers["sec-websocket-key"];
        if (!key) { socket.destroy(); return; }
        socket.write(
          "HTTP/1.1 101 Switching Protocols\r\n" +
          "Upgrade: websocket\r\n" +
          "Connection: Upgrade\r\n" +
          "Sec-WebSocket-Accept: " + wsAccept(key) + "\r\n\r\n"
        );
        this.peers.set(port, socket);
        this.bufs.set(socket, Buffer.alloc(0));
        socket.on("data", (chunk) => this.onData(socket, chunk));
        socket.on("close", () => { this.peers.delete(port); this.bufs.delete(socket); });
        socket.on("error", () => { this.peers.delete(port); this.bufs.delete(socket); });
      });
      srv.listen(port, "127.0.0.1");
      this.servers.add(srv);
    }
  }

  stop(): void {
    for (const [, p] of this.pending) { clearTimeout(p.timer); p.reject(new Error("Server shutting down")); }
    this.pending.clear();
    for (const srv of this.servers) srv.close();
    for (const sock of this.peers.values()) sock.destroy();
    this.peers.clear();
    this.bufs.clear();
  }

  get connected(): boolean {
    return this.peers.size > 0;
  }

  async call(code: string): Promise<unknown> {
    if (!this.connected) throw new Error("Godot editor not connected — is the plugin enabled and Godot running?");
    const peer = this.peers.values().next().value as Duplex;
    const id = this.nextId++;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`Request timed out after ${REQUEST_TIMEOUT / 1000}s`));
      }, REQUEST_TIMEOUT);
      this.pending.set(id, { resolve, reject, timer });
      wsSend(peer, JSON.stringify({ jsonrpc: "2.0", id, method: "run_gdscript", params: { code } }));
    });
  }

  private onData(socket: Duplex, chunk: Buffer): void {
    let buf = Buffer.concat([this.bufs.get(socket)!, chunk]);
    while (true) {
      const frame = decodeFrame(buf);
      if (!frame) break;
      buf = buf.subarray(frame.total);

      if (frame.opcode === 0x8) return; // close
      if (frame.opcode === 0x9) { // ping
        const pong = Buffer.alloc(2);
        pong[0] = 0x8a; pong[1] = 0;
        socket.write(pong);
        continue;
      }
      if (frame.opcode !== 0x1) continue; // not text

      const text = frame.payload.toString("utf8");
      this.dispatch(socket, text);
    }
    this.bufs.set(socket, buf);
  }

  private dispatch(socket: Duplex, text: string): void {
    let msg: Record<string, unknown>;
    try { msg = JSON.parse(text); } catch { return; }

    if (msg.method === "ping") {
      if (msg.id != null) wsSend(socket, JSON.stringify({ jsonrpc: "2.0", id: msg.id, result: { pong: true } }));
      return;
    }

    if (msg.method === "pong" || msg.method === "auth") return;

    if (typeof msg.id === "number" && this.pending.has(msg.id)) {
      const { resolve, reject, timer } = this.pending.get(msg.id)!;
      clearTimeout(timer);
      this.pending.delete(msg.id);
      if (msg.error) reject(new Error(typeof msg.error === "object" ? JSON.stringify(msg.error) : String(msg.error)));
      else resolve(msg.result);
    }
  }
}

const godot = new GodotBridge();

const server = new Server(
  { name: "godot-mcp", version: "0.1.0" },
  { capabilities: { tools: {} } },
);

const TOOL_DEFS = [
  {
    name: "godot_execute",
    description: "Execute GDScript code in the Godot editor. The code runs as a function body and its return value is sent back. Access EditorInterface, get_node, etc. directly.",
    inputSchema: {
      type: "object",
      properties: {
        code: { type: "string", description: "GDScript expression or block. Must return a value. Example: Engine.get_version_info()" },
      },
      required: ["code"],
    },
  },
  {
    name: "godot_info",
    description: "Get project info from the Godot editor (name, version, settings).",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "godot_screenshot",
    description: "Capture the Godot editor viewport as a PNG image.",
    inputSchema: { type: "object", properties: {} },
  },
  {
    name: "godot_status",
    description: "Check if Godot editor is connected to this server.",
    inputSchema: { type: "object", properties: {} },
  },
];

server.setRequestHandler(ListToolsRequestSchema, async () => ({ tools: TOOL_DEFS }));

server.setRequestHandler(CallToolRequestSchema, async (req) => {
  const { name, arguments: args } = req.params;
  try {
    switch (name) {
      case "godot_execute": {
        const code = args?.code as string;
        if (!code) throw new Error("code is required");
        const result = await godot.call(code);
        return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
      }
      case "godot_info": {
        const result = await godot.call('return{name:ProjectSettings.get_setting("application/config/name",""),version:Engine.get_version_info()}');
        return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
      }
      case "godot_screenshot": {
        const gdscript = 'var v=EditorInterface.get_editor_viewport_3d(0);if v==null:v=EditorInterface.get_editor_main_screen();var img=v.get_texture().get_image();var buf=img.save_png_to_buffer();return{image_base64:Marshalls.raw_to_base64(buf),width:img.get_width(),height:img.get_height(),format:"png"}';
        const result = await godot.call(gdscript) as Record<string, unknown>;
        const base64 = result?.image_base64 as string;
        if (base64) {
          return { content: [
            { type: "text", text: `Screenshot: ${result.width}x${result.height} PNG` },
            { type: "image", data: base64, mimeType: "image/png" },
          ]};
        }
        return { content: [{ type: "text", text: JSON.stringify(result, null, 2) }] };
      }
      case "godot_status": {
        return { content: [{ type: "text", text: godot.connected ? "Connected to Godot editor" : "Not connected — start Godot with the MCP plugin enabled" }] };
      }
      default:
        throw new Error(`Unknown tool: ${name}`);
    }
  } catch (err: unknown) {
    const message = err instanceof Error ? err.message : typeof err === "object" && err !== null ? JSON.stringify(err) : String(err);
    return { content: [{ type: "text", text: `Error: ${message}` }], isError: true };
  }
});

async function main() {
  godot.start();
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((err) => { console.error("Fatal:", err); process.exit(1); });
