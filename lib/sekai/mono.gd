class_name Mono

var props := {}

var sekai: Sekai
var define: MonoDefine

func _into_sekai(psekai: Sekai) -> void:
	sekai = psekai
	define.finalize()

func set_define(pdefine: MonoDefine) -> void:
	define = pdefine

func get_prop(key: Variant, default = null) -> Variant:
	var ovalue = props.get(key)
	if ovalue != null: return ovalue
	return define.get_prop(key, default)

func set_prop(key: Variant, value) -> Variant:
	var prev = get_prop(key)
	if prev != value:
		var watcher = define.get_watcher(key)
		if watcher != null: value = watcher.call(sekai, self, prev, value)
	var rawv = define.get_prop(key)
	if rawv != value:
		props[key] = value
	else:
		props.erase(key)
	return value

func get_method(key: StringName) -> Variant:
	return define.get_method(key)

func call_method(key: StringName, argv := []) -> Variant:
	var vargv := [sekai, self]
	vargv.append_array(argv)
	var handle = define.get_method(key)
	if handle != null: return handle.callv(vargv)
	return null

func get_item() -> SekaiItem:
	return SekaiItem.new()

func is_need_collision() -> bool:
	return get_prop(&"need_collision", false)

func is_need_route() -> bool:
	return get_prop(&"need_route", false)

func will_route(point: Vector2, z_pos: int) -> Mono:
	if floori(get_prop(&"position_z")) == z_pos:
		if get_prop(&"routable"):
			var box := get_prop(&"route_box") as Rect2
			var pos := get_prop(&"position") as Vector2
			box = Rect2(pos + box.position, box.size)
			if box.has_point(point):
				return self
	return null

func will_collide(region: Rect2, z_pos: int) -> Mono:
	if floori(get_prop(&"position_z")) == z_pos:
		if get_prop(&"collisible"):
			var box := get_prop(&"collision_box") as Rect2
			var pos := get_prop(&"position") as Vector2
			if Rect2(pos + box.position, box.size).intersects(region):
				return self
	return null
