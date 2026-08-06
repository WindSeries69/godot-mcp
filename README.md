# godot-mcp

Minimal MCP bridge for the [Godot MCP Pro](https://github.com/youichi-uda/godot-mcp-pro) editor addon.

6 tools instead of 175 — no catalogue to maintain. Connects AI assistants (Claude Code, Cursor, etc.) directly to your Godot editor.

```
AI Assistant <--stdio/MCP--> godot-mcp <--WebSocket:6505--> Godot Editor Plugin
```

## Setup

1. Install the [Godot MCP Pro](https://github.com/youichi-uda/godot-mcp-pro) addon in your Godot project and enable it
2. Build and run this server:

```bash
npm install && npm run build && npm start
```

3. Add to your MCP client config (`.mcp.json`, `claude.json`, `opencode.json`):

```json
{
  "mcpServers": {
    "godot-mcp": {
      "command": "node",
      "args": ["/path/to/godot-mcp/dist/index.js"]
    }
  }
}
```

The server listens on ports **6505–6514** (configurable via `GODOT_MCP_PORT`). The Godot addon connects automatically.

## Tools

| Tool | Description |
|------|-------------|
| `godot_call` | Call any of the 175+ addon methods |
| `godot_list_methods` | List available methods by category |
| `godot_info` | Project info (shorthand) |
| `godot_screenshot` | Capture editor viewport as PNG image |
| `godot_execute` | Run GDScript in the editor |
| `godot_status` | Check connection to Godot |

`godot_call` is the only tool you need — the rest are convenience shortcuts. See `godot_list_methods` for the full catalog.

## How it works

The Godot MCP Pro addon connects to this server via WebSocket (JSON-RPC 2.0). The server translates MCP tool calls into JSON-RPC requests and forwards them to Godot. Responses come back through the same channel.

The server uses raw WebSocket framing (Node.js built-in `http` + `crypto`), no library dependency. Compatible with Godot 4.x GDScript WebSocketPeer.

## License

MIT

---

# godot-mcp (Français)

Pont MCP minimal pour l'addon éditeur [Godot MCP Pro](https://github.com/youichi-uda/godot-mcp-pro).

6 outils au lieu de 175 — aucun catalogue à maintenir. Connecte les assistants IA (Claude Code, Cursor…) directement à votre éditeur Godot.

```
Assistant IA <--stdio/MCP--> godot-mcp <--WebSocket:6505--> Plugin Godot
```

## Installation

1. Installez l'addon [Godot MCP Pro](https://github.com/youichi-uda/godot-mcp-pro) dans votre projet Godot et activez-le
2. Compilez et lancez ce serveur :

```bash
npm install && npm run build && npm start
```

3. Ajoutez à la config de votre client MCP (`.mcp.json`, `claude.json`, `opencode.json`) :

```json
{
  "mcpServers": {
    "godot-mcp": {
      "command": "node",
      "args": ["/chemin/vers/godot-mcp/dist/index.js"]
    }
  }
}
```

Le serveur écoute sur les ports **6505–6514** (configurable via `GODOT_MCP_PORT`). L'addon Godot s'y connecte automatiquement.

## Outils

| Outil | Description |
|-------|-------------|
| `godot_call` | Appelle n'importe quelle méthode de l'addon (175+) |
| `godot_list_methods` | Liste les méthodes disponibles par catégorie |
| `godot_info` | Infos projet (raccourci) |
| `godot_screenshot` | Capture la vue éditeur en PNG |
| `godot_execute` | Exécute du GDScript dans l'éditeur |
| `godot_status` | Vérifie la connexion à Godot |

`godot_call` est le seul outil nécessaire — les autres sont des raccourcis. Voir `godot_list_methods` pour le catalogue complet.

## Fonctionnement

L'addon Godot MCP Pro se connecte à ce serveur via WebSocket (JSON-RPC 2.0). Le serveur traduit les appels d'outils MCP en requêtes JSON-RPC vers Godot, et transmet les réponses en sens inverse.

Le serveur utilise le framing WebSocket natif (modules `http` + `crypto` de Node.js), sans bibliothèque externe. Compatible Godot 4.x.

## Licence

MIT
