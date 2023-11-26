class_name MonoMap

var size := Vector2(0, 0)
var offset := Vector3(0, 0, 0)
var offset_xy: Vector2
var data := PackedInt32Array([])

var sekai: Sekai

var map := []
var layers := []

func _into_sekai(psekai: Sekai) -> void:
	sekai = psekai
	offset_xy = Vector2(offset.x, offset.y)
	var length := (size.x * size.y) as int
	
	_clear_layers()
	layers.resize(size.y as int)
	for iy in size.y:
		var layer := sekai.make_item()
		layers[iy] = layer
	
	_clear_map()
	map.resize(length)
	for i in length:
		var ref := data[i % data.size()]
		if ref >= 0:
			var ptr := MapPointer.new(
				self,
				Vector3(i % int(size.x) + offset.x, int(i / size.x) + offset.y, offset.z),
				layers[int(i / size.x)],
			)
			ptr.set_define(sekai.get_define(ref))
			ptr._into_sekai(sekai)
			map[i] = ptr
	
	for iy in size.y:
		var layer := layers[iy] as SekaiItem
		layer.set_y(iy + offset.y + floorf(offset.z) * 64)
		var need_process := false
		for i in range(iy * size.x, (iy + 1) * size.x):
			if map[i] != null and map[i].get_prop(&"need_process"): need_process = true; break
		if need_process:
			layer.on_process.connect(func ():
				for i in range(iy * size.x, (iy + 1) * size.x):
					if map[i] != null and map[i].get_prop(&"processing"):
						map[i].call_method(&"process"))
		layer.on_draw.connect(func () -> void:
			for i in range(iy * size.x, (iy + 1) * size.x):
				if map[i] != null:
					map[i].draw())
		sekai.add_child.call_deferred(layer)

func _outof_sekai() -> void:
	_clear_layers()
	_clear_map()
	sekai = null

func _clear_layers() -> void:
	for layer in layers:
		sekai.remove_child(layer)
		layer.queue_free()
	layers.clear()

func _clear_map() -> void:
	map.clear()

func get_ptr(pos: Vector2i) -> Variant:
	if Rect2i(Vector2i(), size).has_point(pos):
		return map[size.x * pos.y + pos.x]
	return null

class MapPointer extends Mono:
	var map: MonoMap
	var item: SekaiItem
	var position_z: float
	
	func _init(pmap: MonoMap, pos: Vector3, pitem: SekaiItem) -> void:
		map = pmap
		position = pos
		item = pitem

	func draw() -> void:
		if get_prop(&"visible"):
			call_method(&"draw")

func is_need_collision() -> bool:
	var need_collision := false
	for ptr in map:
		if ptr != null and ptr.is_need_collision(): need_collision = true
	return need_collision

func is_need_route() -> bool:
	var need_route := false
	for ptr in map:
		if ptr != null and ptr.is_need_route(): need_route = true
	return need_route

func will_route(point: Vector2, z_pos: int) -> Mono:
	if floori(offset.z) == z_pos:
		var cen := Vector2i((point - offset_xy).round())
		if Rect2i(Vector2i(), size).grow(1).has_point(cen):
			# center
			var ptr = get_ptr(cen)
			if ptr and ptr.will_route(point, z_pos): return ptr
			return null
	return null

func will_collide(region: Rect2, z_pos: int) -> Mono:
	if floori(offset.z) == z_pos:
		var cen := Vector2i((region.get_center() - offset_xy).round())
		if Rect2i(Vector2i(), size).grow(1).has_point(cen):
			# center
			var ptr = get_ptr(cen)
			if ptr and ptr.will_collide(region, z_pos): return ptr
			# sides
			ptr = get_ptr(cen + Vector2i(1, 0))
			if ptr and ptr.will_collide(region, z_pos): return ptr
			ptr = get_ptr(cen + Vector2i(0, 1))
			if ptr and ptr.will_collide(region, z_pos): return ptr
			ptr = get_ptr(cen + Vector2i(-1, 0))
			if ptr and ptr.will_collide(region, z_pos): return ptr
			ptr = get_ptr(cen + Vector2i(0, -1))
			if ptr and ptr.will_collide(region, z_pos): return ptr
			# corners
			ptr = get_ptr(cen + Vector2i(1, 1))
			if ptr and ptr.will_collide(region, z_pos): return ptr
			ptr = get_ptr(cen + Vector2i(1, -1))
			if ptr and ptr.will_collide(region, z_pos): return ptr
			ptr = get_ptr(cen + Vector2i(-1, 1))
			if ptr and ptr.will_collide(region, z_pos): return ptr
			ptr = get_ptr(cen + Vector2i(-1, -1))
			if ptr and ptr.will_collide(region, z_pos): return ptr
			return null
	return null
