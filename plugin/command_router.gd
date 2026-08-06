@tool
extends Node

var editor_plugin: EditorPlugin

var _command_handlers: Dictionary = {}  # method_name -> Callable
var _disabled_tools: Dictionary = {}  # method_name -> true

const TOOL_CONFIG_PATH := "user://mcp_tool_config.cfg"


func _ready() -> void:
	_load_tool_config()
	_register_commands()


func _register_commands() -> void:
	var command_classes := [
		preload("res://plugin/commands/project_commands.gd"),
		preload("res://plugin/commands/scene_commands.gd"),
		preload("res://plugin/commands/node_commands.gd"),
		preload("res://plugin/commands/script_commands.gd"),
		preload("res://plugin/commands/editor_commands.gd"),
		preload("res://plugin/commands/input_commands.gd"),
		preload("res://plugin/commands/runtime_commands.gd"),
		preload("res://plugin/commands/animation_commands.gd"),
		preload("res://plugin/commands/tilemap_commands.gd"),
		preload("res://plugin/commands/theme_commands.gd"),
		preload("res://plugin/commands/profiling_commands.gd"),
		preload("res://plugin/commands/batch_commands.gd"),
		preload("res://plugin/commands/shader_commands.gd"),
		preload("res://plugin/commands/export_commands.gd"),
		preload("res://plugin/commands/resource_commands.gd"),
		preload("res://plugin/commands/input_map_commands.gd"),
		preload("res://plugin/commands/scene_3d_commands.gd"),
		preload("res://plugin/commands/physics_commands.gd"),
		preload("res://plugin/commands/analysis_commands.gd"),
		preload("res://plugin/commands/animation_tree_commands.gd"),
		preload("res://plugin/commands/audio_commands.gd"),
		preload("res://plugin/commands/navigation_commands.gd"),
		preload("res://plugin/commands/particle_commands.gd"),
		preload("res://plugin/commands/test_commands.gd"),
		preload("res://plugin/commands/android_commands.gd"),
		preload("res://plugin/commands/headless_commands.gd"),
	]

	for cmd_class in command_classes:
		var cmd: Node = cmd_class.new()
		cmd.editor_plugin = editor_plugin
		add_child(cmd)
		var methods: Dictionary = cmd.get_commands()
		for method_name: String in methods:
			_command_handlers[method_name] = methods[method_name]

	print("[MCP] Registered %d commands" % _command_handlers.size())


func execute(method: String, params: Dictionary) -> Dictionary:
	if not _command_handlers.has(method):
		return {
			"error": {
				"code": -32601,
				"message": "Method not found: %s" % method,
				"data": {"available_methods": _command_handlers.keys()}
			}
		}

	if _disabled_tools.has(method):
		return {
			"error": {
				"code": -32603,
				"message": "Tool '%s' is disabled in MCP Server settings" % method
			}
		}

	var handler: Callable = _command_handlers[method]
	# Not typed as Dictionary on assignment: a handler that returns something
	# else would raise here, aborting the coroutine so no response is ever
	# sent and the caller waits out its whole timeout instead of being told
	# what went wrong.
	var result: Variant = await handler.call(params)
	if not result is Dictionary:
		return {
			"error": {
				"code": -32603,
				"message": "Handler for '%s' returned %s instead of a result dictionary" % [
					method, type_string(typeof(result))
				],
			}
		}
	return result


func get_available_methods() -> Array:
	return _command_handlers.keys()


func is_tool_disabled(method: String) -> bool:
	return _disabled_tools.has(method)


func set_tool_disabled(method: String, disabled: bool) -> void:
	if disabled:
		_disabled_tools[method] = true
	else:
		_disabled_tools.erase(method)
	_save_tool_config()


func set_all_tools_disabled(disabled: bool) -> void:
	if disabled:
		for method: String in _command_handlers:
			_disabled_tools[method] = true
	else:
		_disabled_tools.clear()
	_save_tool_config()


func _load_tool_config() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(TOOL_CONFIG_PATH) != OK:
		return
	if not cfg.has_section("disabled_tools"):
		return
	for method: String in cfg.get_section_keys("disabled_tools"):
		if cfg.get_value("disabled_tools", method, false):
			_disabled_tools[method] = true


func _save_tool_config() -> void:
	var cfg := ConfigFile.new()
	for method: String in _disabled_tools:
		cfg.set_value("disabled_tools", method, true)
	cfg.save(TOOL_CONFIG_PATH)
