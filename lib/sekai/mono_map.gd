class_name MonoMap

var size := Vector2(0, 0)
var cell_size := Vector3(1, 1, 1)
var cell_size_xy: Vector2
var offset := Vector3(0, 0, 0)
var offset_xy: Vector2
var size_rti: Rect2i
var data := PackedInt32Array([])

var sekai: Sekai

var map := []
var layers := []

func _into_sekai() -> void:
	cell_size_xy = Vector2(cell_size.x, cell_size.y)
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
			var mono := VarTileMono.new(
				sekai.get_define(ref),
				self,
				Vector3(i % int(size.x), int(i / size.x), 0) * cell_size + offset,
				layers[int(i / size.x)],
			)
			mono.sekai = sekai
			mono._into_sekai()
			map[i] = mono
	
	for iy in size.y:
		var layer := layers[iy] as SekaiItem
		layer.set_y(iy * cell_size.y + offset.y + floorf(offset.z) * 64)
		var ids := range(iy * size.x, (iy + 1) * size.x)
		var need_process := false
		for i in ids:
			if map[i] and map[i].getp(&"need_process"): need_process = true; break
		if need_process:
			layer.on_process.connect(func ():
				for i in ids:
					if map[i] and map[i].getp(&"processing"):
						map[i].emitm(&"on_process"))
		layer.on_draw.connect(func () -> void:
			for i in ids:
				if map[i]:
					map[i].callm(&"on_draw", layer))
		sekai.add_child.call_deferred(layer)

func _outof_sekai() -> void:
	_clear_layers()
	_clear_map()

func _on_init() -> void:
	for mono in map:
		if mono != null: mono._on_init()

func _on_store() -> void:
	for mono in map:
		if mono != null: mono._on_store()

func _on_restore() -> void:
	for mono in map:
		if mono != null: mono._on_restore()

func _clear_layers() -> void:
	for layer in layers:
		sekai.remove_child(layer)
		layer.queue_free()
	layers.clear()

func _clear_map() -> void:
	map.clear()

func to_data() -> Dictionary:
	return {
		&"size": size,
		&"cell_size": cell_size,
		&"offset": offset,
		&"data": data,
	}

func from_data(_sekai, pdata: Dictionary):
	size = pdata[&"size"]
	cell_size = pdata[&"cell_size"]
	offset = pdata[&"offset"]
	data = pdata[&"data"]

func get_mono(pos: Vector2i) -> Variant:
	if size_rti.has_point(pos):
		return map[size.x * pos.y + pos.x]
	return null

func get_pos(point: Vector2) -> Variant:
	var pos := Vector2i(((point - offset_xy) / cell_size_xy).round())
	if size_rti.has_point(pos):
		return map[size.x * pos.y + pos.x]
	return null

func set_pos(point: Vector2, mono: Variant) -> void:
	var pos := Vector2i(((point - offset_xy) / cell_size_xy).round())
	if size_rti.has_point(pos):
		map[size.x * pos.y + pos.x] = mono

func get_monos_by_pos(pos: Vector3) -> Array:
	if abs(offset.z - pos.z) < cell_size.z / 2:
		var mono = get_pos(Vector2(pos.x, pos.y))
		if mono != null:
			return [mono]
	return []

class VarTileMono extends Mono:
	var map: MonoMap
	var item: SekaiItem
	
	func _init(pdefine: MonoDefine, pmap: MonoMap, pos: Vector3, pitem: SekaiItem) -> void:
		define = pdefine
		map = pmap
		position = pos
		item = pitem
	
	func destroy() -> void:
		_outof_sekai()
		map.set_pos(Vector2(position.x, position.y), null)
		
	func upgrade() -> VarTileMono:
		return self

class ConstTileMono extends Mono:
	var map: MonoMap
	var item: SekaiItem
	
	func _init(pdefine: MonoDefine, pmap: MonoMap, pos: Vector3, pitem: SekaiItem) -> void:
		define = pdefine
		map = pmap
		position = pos
		item = pitem
	
	func destroy() -> void:
		_outof_sekai()
		map.set_pos(Vector2(position.x, position.y), null)
	
	func upgrade() -> VarTileMono:
		var nmono := VarTileMono.new(define, map, position, item)
		nmono.sekai = sekai
		nmono._into_sekai()
		map.set_pos(Vector2(position.x, position.y), nmono)
		return nmono
	
	func getp(key: StringName) -> Variant:
		return super.getpR(key)
	
	func getpD(key: StringName, default: Variant) -> Variant:
		return super.getpRD(key, default)
	
	func emitm(key: StringName) -> Variant:
		return super.emitmR(key)
	
	func emitmS(key: StringName) -> Variant:
		return super.emitmRS(key)
	
	func callm(key: StringName, arg: Variant) -> Variant:
		return super.callmR(key, arg)
	
	func callmS(key: StringName, arg: Variant) -> Variant:
		return super.callmRS(key, arg)
	
	func applym(key: StringName, argv: Array) -> Variant:
		return super.applymR(key, argv)
	
	func applymS(key: StringName, argv: Array) -> Variant:
		return super.applymRS(key, argv)

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

func will_route(point: Vector2, z_pos: int, result: Array) -> void:
	var monos = get_monos_by_pos(Vector3(point.x, point.y, z_pos))
	if monos.size() > 0: monos[0].will_route(point, z_pos, result)

func will_collide(region: Rect2, z_pos: int, result: Array) -> void:
	if abs(offset.z - z_pos) < cell_size.z / 2:
		var cen := Vector2i(((region.get_center() - offset_xy) / cell_size_xy).round())
		if size_rti.grow(1).has_point(cen):
			# center
			var mono = get_mono(cen)
			if mono != null: mono.will_collide(region, z_pos, result)
			# sides
			mono = get_mono(cen + Vector2i(1, 0))
			if mono != null: mono.will_collide(region, z_pos, result)
			mono = get_mono(cen + Vector2i(0, 1))
			if mono != null: mono.will_collide(region, z_pos, result)
			mono = get_mono(cen + Vector2i(-1, 0))
			if mono != null: mono.will_collide(region, z_pos, result)
			mono = get_mono(cen + Vector2i(0, -1))
			if mono != null: mono.will_collide(region, z_pos, result)
			# corners
			mono = get_mono(cen + Vector2i(1, 1))
			if mono != null: mono.will_collide(region, z_pos, result)
			mono = get_mono(cen + Vector2i(1, -1))
			if mono != null: mono.will_collide(region, z_pos, result)
			mono = get_mono(cen + Vector2i(-1, 1))
			if mono != null: mono.will_collide(region, z_pos, result)
			mono = get_mono(cen + Vector2i(-1, -1))
			if mono != null: mono.will_collide(region, z_pos, result)
