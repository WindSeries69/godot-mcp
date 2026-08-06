@tool
extends Node

const PORTS := range(6505, 6515)
const RETRY := 3.0
const PING := 5.0
const TIMEOUT := 30.0

var _peers: Dictionary = {}
var _open: Dictionary = {}
var _timer: Dictionary = {}
var _ping_t: Dictionary = {}
var _last: Dictionary = {}
var _run := false

func start() -> void:
	_run = true
	for p in PORTS:
		_open[p] = false
		_timer[p] = 0.0
		_plug(p)

func stop() -> void:
	_run = false
	for p in _peers:
		var w: WebSocketPeer = _peers[p]
		if w and w.get_ready_state() == WebSocketPeer.STATE_OPEN:
			w.close(1000)
	_peers.clear()
	_open.clear()

func _plug(port: int) -> void:
	var w := WebSocketPeer.new()
	if w.connect_to_url("ws://127.0.0.1:%d" % port) == OK:
		_peers[port] = w

func _process(d: float) -> void:
	if not _run: return
	for p in PORTS:
		var w: WebSocketPeer = _peers.get(p)
		if w == null:
			_timer[p] = _timer.get(p, 0.0) + d
			if _timer[p] >= RETRY: _timer[p] = 0.0; _plug(p)
			continue
		w.poll()
		match w.get_ready_state():
			WebSocketPeer.STATE_OPEN:
				if not _open.get(p, false):
					_open[p] = true; _last[p] = 0.0; _ping_t[p] = 0.0
				else:
					_last[p] = _last.get(p, 0.0) + d; _ping_t[p] = _ping_t.get(p, 0.0) + d
				while w.get_available_packet_count() > 0:
					_last[p] = 0.0
					_on_msg(w.get_packet().get_string_from_utf8(), p)
				if _last.get(p, 0.0) > TIMEOUT:
					w.close(4000); _open[p] = false; _peers[p] = null
				if _ping_t.get(p, 0.0) >= PING:
					_ping_t[p] = 0.0; w.send_text(JSON.stringify({"jsonrpc":"2.0","method":"ping","params":{}}))
			WebSocketPeer.STATE_CLOSING, WebSocketPeer.STATE_CONNECTING:
				pass
			WebSocketPeer.STATE_CLOSED:
				_open[p] = false; _peers[p] = null

func _on_msg(text: String, port: int) -> void:
	var j = JSON.new()
	if j.parse(text) != OK or not j.data is Dictionary: return
	var m: Dictionary = j.data
	var id = m.get("id")
	var method: String = m.get("method", "")
	var params: Dictionary = m.get("params", {}) if m.get("params") is Dictionary else {}

	if method == "ping":
		var r = {"jsonrpc":"2.0","method":"pong","params":{}} if id == null else {"jsonrpc":"2.0","id":id,"result":{"pong":true}}
		w_send(port, JSON.stringify(r))
		return
	if method == "run_gdscript":
		var code: String = params.get("code", "")
		if code.is_empty():
			w_send(port, JSON.stringify({"jsonrpc":"2.0","id":id,"error":{"code":-32602,"message":"code required"}}))
			return
		var result: Dictionary = await _run(code)
		w_send(port, JSON.stringify({"jsonrpc":"2.0","id":id} + result))
		return
	if id != null:
		w_send(port, JSON.stringify({"jsonrpc":"2.0","id":id,"error":{"code":-32601,"message":"Unknown: "+method}}))

func _run(code: String) -> Dictionary:
	var s := GDScript.new()
	s.source_code = "extends RefCounted\nfunc _run():\n\treturn " + code.replace("\n", "\n\t")
	var err := s.reload()
	if err != OK: return {"error":{"code":-32603,"message":"Compile: "+error_string(err)}}
	var obj = s.new()
	if not obj: return {"error":{"code":-32603,"message":"Instantiate failed"}}
	return {"result": obj._run()}

func w_send(port: int, text: String) -> void:
	var w: WebSocketPeer = _peers.get(port)
	if w and _open.get(port, false):
		w.send_text(text)
