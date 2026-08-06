@tool
extends RefCounted

## Target types whose value may legitimately arrive as JSON text.
const _STRUCTURED_TYPES := {
	TYPE_VECTOR2: true, TYPE_VECTOR2I: true,
	TYPE_VECTOR3: true, TYPE_VECTOR3I: true,
	TYPE_RECT2: true, TYPE_COLOR: true,
	TYPE_ARRAY: true, TYPE_DICTIONARY: true,
}

## Parse a string value into the appropriate Godot type
static func parse_value(value: Variant, target_type: int = TYPE_NIL) -> Variant:
	if value == null:
		return null

	# If already the correct type, return as-is
	if target_type == TYPE_NIL:
		return _auto_parse(value)

	# Some clients stringify object arguments before sending them, so a
	# structured value can arrive as its JSON text. Observed with a Color
	# passed as {"r":..,"g":..}: the string matched no colour syntax and the
	# property was silently set to white.
	if value is String and _STRUCTURED_TYPES.has(target_type):
		var text := (value as String).strip_edges()
		if (text.begins_with("{") and text.ends_with("}")) or (text.begins_with("[") and text.ends_with("]")):
			var decoded: Variant = JSON.parse_string(text)
			if decoded != null:
				value = decoded

	match target_type:
		TYPE_BOOL:
			if value is bool: return value
			if value is String: return value.to_lower() in ["true", "1", "yes"]
			if value is int or value is float: return bool(value)
			return false
		TYPE_INT:
			# int()/float() raise on arrays and dictionaries, and a raise inside
			# a command handler aborts it before any response is sent — the
			# caller then waits out its whole timeout with no idea why.
			if value is int or value is float or value is bool:
				return int(value)
			if value is String and (value as String).is_valid_float():
				return int((value as String).to_float())
			return 0
		TYPE_FLOAT:
			if value is int or value is float or value is bool:
				return float(value)
			if value is String and (value as String).is_valid_float():
				return (value as String).to_float()
			return 0.0
		TYPE_STRING:
			return str(value)
		TYPE_VECTOR2:
			return _parse_vector2(value)
		TYPE_VECTOR2I:
			return _parse_vector2i(value)
		TYPE_VECTOR3:
			return _parse_vector3(value)
		TYPE_VECTOR3I:
			return _parse_vector3i(value)
		TYPE_RECT2:
			return _parse_rect2(value)
		TYPE_COLOR:
			return _parse_color(value)
		TYPE_NODE_PATH:
			return NodePath(str(value))
		TYPE_ARRAY:
			if value is Array: return value
			return [value]
		TYPE_DICTIONARY:
			if value is Dictionary: return value
			return {}
		TYPE_OBJECT:
			if value is Object:
				return value
			if value is String:
				var s: String = value
				if (s.begins_with("res://") or s.begins_with("uid://")) and ResourceLoader.exists(s):
					return ResourceLoader.load(s)
				# Unresolvable string for an Object-typed property: return null so
				# callers can detect the failure instead of coercing to null silently.
				return null
			return value
		_:
			return value


static func _auto_parse(value: Variant) -> Variant:
	if not value is String:
		return value

	var s: String = value

	# Boolean
	if s == "true": return true
	if s == "false": return false

	# Integer
	if s.is_valid_int(): return s.to_int()

	# Float
	if s.is_valid_float(): return s.to_float()

	# Vector2: "Vector2(x, y)" or "(x, y)" or "x, y"
	if s.begins_with("Vector2(") or s.begins_with("Vector2i("):
		return _parse_vector2(s)

	# Vector3
	if s.begins_with("Vector3(") or s.begins_with("Vector3i("):
		return _parse_vector3(s)

	# Color
	if s.begins_with("Color(") or s.begins_with("#"):
		return _parse_color(s)

	# Rect2
	if s.begins_with("Rect2("):
		return _parse_rect2(s)

	# Resource path (covers unset Object properties, where typeof(null) is TYPE_NIL)
	if (s.begins_with("res://") or s.begins_with("uid://")) and ResourceLoader.exists(s):
		return ResourceLoader.load(s)

	return s


static func _extract_numbers(s: String) -> PackedFloat64Array:
	# Remove type prefix and parentheses
	var cleaned := s
	for prefix in ["Vector3i(", "Vector3(", "Vector2i(", "Vector2(", "Rect2(", "Color(", "("]:
		if cleaned.begins_with(prefix):
			cleaned = cleaned.substr(prefix.length())
			break
	cleaned = cleaned.trim_suffix(")")
	cleaned = cleaned.strip_edges()

	var parts := cleaned.split(",")
	var numbers: PackedFloat64Array = []
	for part in parts:
		numbers.append(part.strip_edges().to_float())
	return numbers


## float() raises on arrays and dictionaries; component parsing must not.
static func _num(value: Variant, default: float = 0.0) -> float:
	if value is float:
		return value
	if value is int:
		return float(value)
	if value is bool:
		return 1.0 if value else 0.0
	if value is String and (value as String).is_valid_float():
		return (value as String).to_float()
	return default


static func _parse_vector2(value: Variant) -> Vector2:
	if value is Vector2: return value
	if value is Dictionary:
		return Vector2(_num(value.get("x", 0)), _num(value.get("y", 0)))
	var nums := _extract_numbers(str(value))
	if nums.size() >= 2:
		return Vector2(nums[0], nums[1])
	return Vector2.ZERO


static func _parse_vector2i(value: Variant) -> Vector2i:
	var v := _parse_vector2(value)
	return Vector2i(int(v.x), int(v.y))


static func _parse_vector3(value: Variant) -> Vector3:
	if value is Vector3: return value
	if value is Dictionary:
		return Vector3(_num(value.get("x", 0)), _num(value.get("y", 0)), _num(value.get("z", 0)))
	var nums := _extract_numbers(str(value))
	if nums.size() >= 3:
		return Vector3(nums[0], nums[1], nums[2])
	return Vector3.ZERO


static func _parse_vector3i(value: Variant) -> Vector3i:
	var v := _parse_vector3(value)
	return Vector3i(int(v.x), int(v.y), int(v.z))


static func _parse_rect2(value: Variant) -> Rect2:
	if value is Rect2: return value
	if value is Dictionary:
		return Rect2(
			_num(value.get("x", 0)), _num(value.get("y", 0)),
			_num(value.get("w", value.get("width", 0))),
			_num(value.get("h", value.get("height", 0)))
		)
	var nums := _extract_numbers(str(value))
	if nums.size() >= 4:
		return Rect2(nums[0], nums[1], nums[2], nums[3])
	return Rect2()


static func _parse_color(value: Variant) -> Color:
	if value is Color: return value
	# serialize_value() reports a Color as {"r","g","b","a","html"}; without
	# this, feeding that same dictionary back set the property to white.
	if value is Dictionary:
		var d: Dictionary = value
		if d.has("html") and d["html"] is String and Color.html_is_valid(d["html"]):
			return Color.html(d["html"])
		if d.has("r") or d.has("g") or d.has("b"):
			return Color(_num(d.get("r", 0.0)), _num(d.get("g", 0.0)), _num(d.get("b", 0.0)), _num(d.get("a", 1.0)))
		return Color.WHITE
	var s := str(value)
	if s.begins_with("#"):
		return Color.html(s)
	if s.begins_with("Color("):
		var nums := _extract_numbers(s)
		match nums.size():
			3: return Color(nums[0], nums[1], nums[2])
			4: return Color(nums[0], nums[1], nums[2], nums[3])
	# Try named color
	if Color.html_is_valid(s):
		return Color.html(s)
	return Color.WHITE


## Serialize a Variant to JSON-safe representation
static func serialize_value(value: Variant) -> Variant:
	if value == null:
		return null
	match typeof(value):
		TYPE_VECTOR2:
			var v: Vector2 = value
			return {"x": v.x, "y": v.y}
		TYPE_VECTOR2I:
			var v: Vector2i = value
			return {"x": v.x, "y": v.y}
		TYPE_VECTOR3:
			var v: Vector3 = value
			return {"x": v.x, "y": v.y, "z": v.z}
		TYPE_VECTOR3I:
			var v: Vector3i = value
			return {"x": v.x, "y": v.y, "z": v.z}
		TYPE_RECT2:
			var r: Rect2 = value
			return {"x": r.position.x, "y": r.position.y, "width": r.size.x, "height": r.size.y}
		TYPE_COLOR:
			var c: Color = value
			return {"r": c.r, "g": c.g, "b": c.b, "a": c.a, "html": "#" + c.to_html()}
		TYPE_NODE_PATH:
			return str(value)
		TYPE_OBJECT:
			if value is Resource:
				var res: Resource = value
				return {"type": res.get_class(), "path": res.resource_path}
			return str(value)
		TYPE_ARRAY:
			var arr: Array = value
			var result: Array = []
			for item in arr:
				result.append(serialize_value(item))
			return result
		TYPE_DICTIONARY:
			var dict: Dictionary = value
			var result: Dictionary = {}
			for key in dict:
				result[str(key)] = serialize_value(dict[key])
			return result
		_:
			return value
