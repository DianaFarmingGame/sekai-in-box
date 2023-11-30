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

func getp(key: StringName) -> Variant:
	var ovalue = props.get(key)
	if ovalue != null: return ovalue
	return define._props[key]

func getpL(layer: StringName, key: StringName) -> void:
	pass

func getpD(key: StringName, default = null) -> Variant:
	var ovalue = props.get(key)
	if ovalue != null: return ovalue
	return define._props.get(key, default)

func getpDL(layer: StringName, key: StringName, default = null) -> void:
	pass

func setp(key: StringName, value: Variant) -> void:
	var prev = getp(key)
	if prev != value:
		var watcher = define._watchers.get(key)
		if watcher != null: value = watcher.call(sekai, self, prev, value)
	var rawv = define._props.get(key)
	if rawv != value:
		props[key] = value
	else:
		props.erase(key)

func setpL(layer: StringName, key: StringName, value: Variant) -> void:
	pass

func pushs(key: StringName, value) -> void:
	pass

func pushsL(key: StringName, value) -> void:
	pass

func emitm(key: StringName) -> Variant:
	return define._props[key].call(sekai, self)

func emitmS(key: StringName) -> Variant:
	var handle = define._props.get(key)
	if handle != null: return handle.call(sekai, self)
	return null

func callm(key: StringName, arg: Variant) -> Variant:
	return define._props[key].call(sekai, self, arg)

func callmS(key: StringName, arg: Variant) -> Variant:
	var handle = define._props.get(key)
	if handle != null: return handle.call(sekai, self, arg)
	return null

func callmv(key: StringName, argv: Array) -> Variant:
	var vargv := [sekai, self]
	vargv.append_array(argv)
	return define._props[key].callv(vargv)

func callmvS(key: StringName, argv: Array) -> Variant:
	var vargv := [sekai, self]
	vargv.append_array(argv)
	var handle = define._props.get(key)
	if handle != null: return handle.callv(vargv)
	return null

func is_need_collision() -> bool:
	return getpD(&"need_collision", false)

func is_need_route() -> bool:
	return getpD(&"need_route", false)

func will_route(point: Vector2, z_pos: int) -> Mono:
	if floori(position.z) == z_pos:
		if getp(&"routable"):
			var box := getp(&"route_box") as Rect2
			box.position += Vector2(position.x, position.y)
			if box.has_point(point):
				return self
	return null

func will_collide(region: Rect2, z_pos: int) -> Mono:
	if floori(position.z) == z_pos:
		if getp(&"collisible"):
			var box := getp(&"collision_box") as Rect2
			box.position += Vector2(position.x, position.y)
			if box.intersects(region):
				return self
	return null
