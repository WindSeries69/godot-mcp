@tool
extends EditorPlugin

var ws: Node

func _enter_tree() -> void:
	ws = preload("ws.gd").new()
	add_child(ws)
	ws.start()

func _exit_tree() -> void:
	ws.stop()
