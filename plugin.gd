@tool
extends EditorPlugin

var ws: Node

func _enter_tree() -> void:
	ws = preload("ws.gd").new()
	add_child(ws)
	ws.start()

func _exit_tree() -> void:
	ws.stop()

static func run(code: String) -> Dictionary:
	var s := GDScript.new()
	s.source_code = "extends RefCounted\nfunc run():\n\treturn " + code.replace("\n", "\n\t")
	s.reload()
	if s.has_source_code() == false:
		return {"error": {"code": -32603, "message": "Script failed to compile"}}
	var err := s.reload()
	if err != OK:
		return {"error": {"code": -32603, "message": "Compile error: " + error_string(err)}}
	var obj = s.new()
	if obj == null:
		return {"error": {"code": -32603, "message": "Failed to instantiate"}}
	var result = obj.run()
	return {"result": result}
