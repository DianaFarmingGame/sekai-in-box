class_name MonoMap extends MonoLike


@export var size := Vector2(0, 0)
@export var offset := Vector2(0, 0)
@export var data := PackedInt32Array([])
#@export var overrides := {} # TODO

var map := []

func _enter_tree() -> void:
	super._enter_tree()
	if sekai == null:
		push_error("parent isn't Sekai"); return
	map.resize(data.size())
	for i in data.size():
		map[i] = MapPointer.new(self, i, data[i])

var layers := []

func _ready() -> void:
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

class MapPointer:
	var idx: int
	var map: MonoMap
	var define: MonoDefine
	var item: SekaiItem
	
	func _init(pmap: MonoMap, pidx: int, ref: int) -> void:
		map = pmap
		idx = pidx
		define = map.sekai.get_define(ref)
		define.finalize()
	
	func get_prop(key: Variant) -> Variant:
		if key == &"position":
			return Vector2(idx % (map.size.x as int), (idx / map.size.x) as int) + map.offset
		# TODO
#		var ovalue = override.get(key)
#		if ovalue != null: return ovalue
		return define.get_prop(key)

	func get_method(key: StringName) -> Variant:
		return define.get_method(key)

	func call_method(key: StringName, argv := []) -> Variant:
		var vargv := [map.sekai, self]
		vargv.append_array(argv)
		return define.get_method(key).callv(vargv)

	func draw() -> void:
		if get_prop(&"visible"):
			call_method(&"draw")
	
	func get_item() -> SekaiItem:
		if item != null: return item
		item = map.layers[(idx / map.size.x) as int]
		return item

#func draw(delta: float, time: float) -> void:
#	for ptr in map:
#		ptr.draw(delta, time)
