class_name Mono

var props := {}

var sekai: Sekai
var define: MonoDefine

var position := Vector3(0, 0, 0)

func _into_sekai(psekai: Sekai) -> void:
	sekai = psekai
	define.finalize()

func _outof_sekai() -> void:
	sekai = null
	define = null

func set_define(pdefine: MonoDefine) -> void:
	define = pdefine

func getp(key: StringName, default = null) -> Variant:
	var ovalue = props.get(key)
	if ovalue != null: return ovalue
	return define._props.get(key, default)

func layer_getp(layer: StringName, key: StringName, default = null) -> void:
	pass

func setp(key: StringName, value) -> void:
	var prev = getp(key)
	if prev != value:
		var watcher = define._watchers.get(key)
		if watcher != null: value = watcher.call(sekai, self, prev, value)
	var rawv = define._props.get(key)
	if rawv != value:
		props[key] = value
	else:
		props.erase(key)

func push_stack(key: StringName, value) -> void:
	pass

func emitmS(key: StringName) -> Variant:
	var handle = define._props.get(key)
	if handle != null: return handle.call(sekai, self)
	return null

func callmS(key: StringName, arg: Variant) -> Variant:
	var handle = define._props.get(key)
	if handle != null: return handle.call(sekai, self, arg)
	return null

func callmvS(key: StringName, argv: Array) -> Variant:
	var vargv := [sekai, self]
	vargv.append_array(argv)
	var handle = define._props.get(key)
	if handle != null: return handle.callv(vargv)
	return null

func emitm(key: StringName) -> Variant:
	return define._props[key].call(sekai, self)

func callm(key: StringName, arg: Variant) -> Variant:
	return define._props[key].call(sekai, self, arg)

func callmv(key: StringName, argv: Array) -> Variant:
	var vargv := [sekai, self]
	vargv.append_array(argv)
	return define._props[key].callv(vargv)

func is_need_collision() -> bool:
	return getp(&"need_collision", false)

func is_need_route() -> bool:
	return getp(&"need_route", false)

func will_route(point: Vector2, z_pos: int) -> Mono:
	if floori(position.z) == z_pos:
		if getp(&"routable"):
			var box := getp(&"route_box") as Rect2
			box = Rect2(Vector2(position.x, position.y) + box.position, box.size)
			if box.has_point(point):
				return self
	return null

func will_collide(region: Rect2, z_pos: int) -> Mono:
	if floori(position.z) == z_pos:
		if getp(&"collisible"):
			var box := getp(&"collision_box") as Rect2
			if Rect2(Vector2(position.x, position.y) + box.position, box.size).intersects(region):
				return self
	return null
