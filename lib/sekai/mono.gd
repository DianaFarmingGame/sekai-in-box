class_name Mono

var sekai: Sekai
var define: MonoDefine
var layers := []

var position := Vector3(0, 0, 0)

func _into_sekai(psekai: Sekai) -> void:
	sekai = psekai
	define.finalize()

func _outof_sekai() -> void:
	define = null
	sekai = null

func set_define(pdefine: MonoDefine) -> void:
	define = pdefine

func cover(layer_name: StringName, layer: Dictionary) -> void:
	layers.push_front([layer_name, layer])

func uncover(layer_name: StringName) -> void:
	for lidx in layers.size():
		if layers[lidx][0] == layer_name:
			layers.remove_at(lidx)
			return

func emit_watcher(key: StringName, value: Variant) -> Variant:
	if getp(key) != value:
		var hkey = StringName("on_" + key)
		var handle = define._props.get(hkey)
		if handle != null: value = handle.call(sekai, self, value)
		var lidx = layers.size() - 1
		while lidx >= 0:
			handle = layers[lidx][1].get(hkey)
			if handle != null: value = handle.call(sekai, self, value)
			lidx -= 1
	return value

# get property methods
#
# D -> Default:	get with default value
# L -> Layer: 	only get on certain layer
# U -> Under: 	only get under certain layer
# B -> Base:	only get on base layer
# R -> Raw:		only get on define

func getp(key: StringName) -> Variant:
	for l in layers:
		var v = l[1].get(key)
		if v != null: return v
	return define._props.get(key)

func getpD(key: StringName, default: Variant) -> Variant:
	for l in layers:
		var v = l[1].get(key)
		if v != null: return v
	return define._props.get(key, default)

func getpL(layer_name: StringName, key: StringName) -> Variant:
	for l in layers:
		if l[0] == layer_name:
			var v = l[1].get(key)
			if v != null: return v
			else: return null
	return null

func getpLD(layer_name: StringName, key: StringName, default: Variant) -> Variant:
	for l in layers:
		if l[0] == layer_name:
			var v = l[1].get(key)
			if v != null: return v
			else: return default
	return default

func getpU(layer_name: StringName, key: StringName) -> Variant:
	var lidx := 0
	while lidx < layers.size():
		if layers[lidx][0] == layer_name:
			lidx += 1
			while lidx < layers.size():
				var v = layers[lidx][1].get(key)
				if v != null: return v
				lidx += 1
			return define._props.get(key)
		lidx += 1
	return null

func getpUD(layer_name: StringName, key: StringName, default: Variant) -> Variant:
	var lidx := 0
	while lidx < layers.size():
		if layers[lidx][0] == layer_name:
			lidx += 1
			while lidx < layers.size():
				var v = layers[lidx][1].get(key)
				if v != null: return v
				lidx += 1
			return define._props.get(key, default)
		lidx += 1
	return default

func getpB(key: StringName) -> Variant:
	if layers.size() > 0:
		return layers[-1][1].get(key)
	return null

func getpBD(key: StringName, default: Variant) -> Variant:
	if layers.size() > 0:
		return layers[-1][1].get(key, default)
	return default

func getpR(key: StringName) -> Variant:
	return define._props.get(key)

func getpRD(key: StringName, default: Variant) -> Variant:
	return define._props.get(key, default)

# set property methods
#
# D -> Direct: 	set without trigger watchers
# L -> Layer: 	only set on certain layer
# B -> Base:	only set on base layer

func setp(key: StringName, value: Variant) -> void:
	for l in layers:
		var v = l[1].get(key)
		if v != null:
			if v != value:
				l[1][key] = emit_watcher(key, value)
			return
	var v = define._props.get(key)
	if define._props.get(key) != value: setpB(key, value)

func setpD(key: StringName, value: Variant) -> void:
	for l in layers:
		var v = l[1].get(key)
		if v != null:
			if v != value:
				l[1][key] = value
			return
	var v = define._props.get(key)
	if define._props.get(key) != value: setpB(key, value)

func setpL(layer_name: StringName, key: StringName, value: Variant) -> void:
	for l in layers:
		if l[0] == layer_name:
			l[1][key] = emit_watcher(key, value)
			return

func setpLD(layer_name: StringName, key: StringName, value: Variant) -> void:
	for l in layers:
		if l[0] == layer_name:
			l[1][key] = value
			return

func setpB(key: StringName, value: Variant) -> void:
	value = emit_watcher(key, value)
	if layers.size() > 0:
		layers[-1][1][key] = value
		return
	cover(&"base", {key: value})

func setpBD(key: StringName, value: Variant) -> void:
	if layers.size() > 0:
		layers[-1][1][key] = value
		return
	cover(&"base", {key: value})

# push stack methods
#
# S -> Sort: 	push key to the sorted place
# L -> Layer: 	only push on certain layer
# B -> Base:	only push on base layer

func pushs(key: StringName, value: Variant) -> void:
	pass

func pushsS(key: StringName, value: Variant) -> void:
	pass

func pushsL(layer_name: StringName, key: StringName, value: Variant) -> void:
	pass

func pushsLS(layer_name: StringName, key: StringName, value: Variant) -> void:
	pass

func pushsB(key: StringName, value: Variant) -> void:
	pass

func pushsBS(key: StringName, value: Variant) -> void:
	pass

# pop stack methods
#
# L -> Layer: 	only pop on certain layer
# B -> Base:	only pop on base layer

func pops(key: StringName) -> void:
	pass

func popsL(layer_name: StringName, key: StringName) -> void:
	pass

func popsB(key: StringName) -> void:
	pass

# call function methods
#
# S -> Safe: 	never fail
# R -> Raw:		only call on define

func emitm(key: StringName) -> Variant:
	var value = null
	var handle = define._props.get(key)
	if handle != null: value = handle.call(sekai, self)
	var lidx = layers.size() - 1
	while lidx >= 0:
		handle = layers[lidx][1].get(key)
		if handle != null: value = handle.call(sekai, self)
		lidx -= 1
	return value

func callm(key: StringName, arg: Variant) -> Variant:
	var value = null
	var handle = define._props.get(key)
	if handle != null: value = handle.call(sekai, self, arg)
	var lidx = layers.size() - 1
	while lidx >= 0:
		handle = layers[lidx][1].get(key)
		if handle != null: value = handle.call(sekai, self, arg)
		lidx -= 1
	return value

func applym(key: StringName, argv: Array) -> Variant:
	var vargv := [sekai, self]
	vargv.append_array(argv)
	var value = null
	var handle = define._props.get(key)
	if handle != null: value = handle.call(sekai, self, vargv)
	var lidx = layers.size() - 1
	while lidx >= 0:
		handle = layers[lidx][1].get(key)
		if handle != null: value = handle.call(sekai, self, vargv)
		lidx -= 1
	return value

func emitmR(key: StringName) -> Variant:
	return define._props[key].call(sekai, self)

func emitmRS(key: StringName) -> Variant:
	var handle = define._props.get(key)
	if handle != null: return handle.call(sekai, self)
	return null

func callmR(key: StringName, arg: Variant) -> Variant:
	return define._props[key].call(sekai, self, arg)

func callmRS(key: StringName, arg: Variant) -> Variant:
	var handle = define._props.get(key)
	if handle != null: return handle.call(sekai, self, arg)
	return null

func applymR(key: StringName, argv: Array) -> Variant:
	var vargv := [sekai, self]
	vargv.append_array(argv)
	return define._props[key].callv(vargv)

func applymRS(key: StringName, argv: Array) -> Variant:
	var vargv := [sekai, self]
	vargv.append_array(argv)
	var handle = define._props.get(key)
	if handle != null: return handle.callv(vargv)
	return null

# accelerator methods

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
