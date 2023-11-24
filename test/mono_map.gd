class_name MonoMap

@export var size := Vector2(0, 0)
@export var offset := Vector2(0, 0)
@export var data := PackedInt32Array([])

var sekai: Sekai

var map := []
var layers := []

func _into_sekai(psekai: Sekai) -> void:
	sekai = psekai
	map.resize(data.size())
	for i in data.size():
		var ptr := MapPointer.new(self, i)
		ptr.define_ref = data[i]
		ptr._into_sekai(sekai)
		map[i] = ptr
	
	_clear_layers()
	layers.resize(size.y as int)
	for iy in size.y:
		var layer := sekai.make_item()
		layer.set_y(iy + offset.y)
		layer.on_draw.connect(func () -> void:
			for i in range(iy * size.x, (iy + 1) * size.x):
				map[i].draw())
		layers[iy] = layer
		sekai.add_child.call_deferred(layer)

func _clear_layers() -> void:
	for layer in layers: sekai.remove_child(layer)
	layers.clear()

class MapPointer extends Mono:
	var idx: int
	var map: MonoMap
	var item: SekaiItem
	
	func _init(pmap: MonoMap, pidx: int) -> void:
		map = pmap
		idx = pidx

	func draw() -> void:
		if get_prop(&"visible"):
			call_method(&"draw")
	
	func get_prop(key: Variant) -> Variant:
		if key == &"position":
			return Vector2(idx % (map.size.x as int), (idx / map.size.x) as int) + map.offset
		return super.get_prop(key)
	
	func get_item() -> SekaiItem:
		if item != null: return item
		item = map.layers[(idx / map.size.x) as int]
		return item
