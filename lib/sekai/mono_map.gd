class_name MonoMap

var size := Vector2(0, 0)
var offset := Vector3(0, 0, 0)
var offset_xy: Vector2
var size_rti: Rect2i
var data := PackedInt32Array([])

var sekai: Sekai

var map := []
var layers := []

func _into_sekai(psekai: Sekai) -> void:
	sekai = psekai
	offset_xy = Vector2(offset.x, offset.y)
	size_rti = Rect2i(Vector2i(), size)
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
			var mono := ConstTileMono.new(
				self,
				Vector3(i % int(size.x) + offset.x, int(i / size.x) + offset.y, offset.z),
				layers[int(i / size.x)],
			)
			mono.set_define(sekai.get_define(ref))
			mono._into_sekai(sekai)
			map[i] = mono
	
	for iy in size.y:
		var layer := layers[iy] as SekaiItem
		layer.set_y(iy + offset.y + floorf(offset.z) * 64)
		var ids := range(iy * size.x, (iy + 1) * size.x).filter(func (i): return map[i] != null)
		var need_process := false
		for i in ids:
			if map[i].getp(&"need_process"): need_process = true; break
		if need_process:
			layer.on_process.connect(func ():
				for i in ids:
					if map[i].getp(&"processing"):
						map[i].emitm(&"process"))
		layer.on_draw.connect(func () -> void:
			for i in ids:
				var mono = map[i]
				mono.callm(&"draw", layer))
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

func get_mono(pos: Vector2i) -> Variant:
	if size_rti.has_point(pos):
		return map[size.x * pos.y + pos.x]
	return null

func get_pos(point: Vector2) -> Variant:
	var pos := Vector2i((point - offset_xy).round())
	if size_rti.has_point(pos):
		return map[size.x * pos.y + pos.x]
	return null

func set_pos(point: Vector2, mono: Variant) -> void:
	var pos := Vector2i((point - offset_xy).round())
	if size_rti.has_point(pos):
		map[size.x * pos.y + pos.x] = mono

class VarTileMono extends Mono:
	var map: MonoMap
	var item: SekaiItem
	
	func _init(pmap: MonoMap, pos: Vector3, pitem: SekaiItem) -> void:
		map = pmap
		position = pos
		item = pitem

class ConstTileMono extends Mono:
	var map: MonoMap
	var item: SekaiItem
	
	func _init(pmap: MonoMap, pos: Vector3, pitem: SekaiItem) -> void:
		map = pmap
		position = pos
		item = pitem

	func getp(key: StringName, default = null) -> Variant:
		return define._props.get(key, default)

	func setp(key: StringName, value) -> void:
		var rawv = define._props.get(key)
		if rawv != value:
			var nmono := VarTileMono.new(map, position, item)
			nmono.set_define(define)
			nmono._into_sekai(sekai)
			map.set_pos(Vector2(position.x, position.y), nmono)
			nmono.setp(key, value)

func is_need_collision() -> bool:
	var need_collision := false
	for mono in map:
		if mono != null and mono.is_need_collision(): need_collision = true
	return need_collision

func is_need_route() -> bool:
	var need_route := false
	for mono in map:
		if mono != null and mono.is_need_route(): need_route = true
	return need_route

func will_route(point: Vector2, z_pos: int) -> Mono:
	if floori(offset.z) == z_pos:
		var cen := Vector2i((point - offset_xy).round())
		if size_rti.grow(1).has_point(cen):
			# center
			var mono = get_mono(cen)
			if mono and mono.will_route(point, z_pos): return mono
			return null
	return null

func will_collide(region: Rect2, z_pos: int) -> Mono:
	if floori(offset.z) == z_pos:
		var cen := Vector2i((region.get_center() - offset_xy).round())
		if size_rti.grow(1).has_point(cen):
			# center
			var mono = get_mono(cen)
			if mono and mono.will_collide(region, z_pos): return mono
			# sides
			mono = get_mono(cen + Vector2i(1, 0))
			if mono and mono.will_collide(region, z_pos): return mono
			mono = get_mono(cen + Vector2i(0, 1))
			if mono and mono.will_collide(region, z_pos): return mono
			mono = get_mono(cen + Vector2i(-1, 0))
			if mono and mono.will_collide(region, z_pos): return mono
			mono = get_mono(cen + Vector2i(0, -1))
			if mono and mono.will_collide(region, z_pos): return mono
			# corners
			mono = get_mono(cen + Vector2i(1, 1))
			if mono and mono.will_collide(region, z_pos): return mono
			mono = get_mono(cen + Vector2i(1, -1))
			if mono and mono.will_collide(region, z_pos): return mono
			mono = get_mono(cen + Vector2i(-1, 1))
			if mono and mono.will_collide(region, z_pos): return mono
			mono = get_mono(cen + Vector2i(-1, -1))
			if mono and mono.will_collide(region, z_pos): return mono
			return null
	return null
