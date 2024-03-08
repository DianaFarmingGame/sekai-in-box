class_name SekaiItem extends Node2D

var base_transform: Transform2D
var offset_transform: Transform2D
var unit_size: Vector3:
	set(v):
		unit_size = v
		ratio_yz = v.y / v.z
var ratio_yz := 1.0

var need_draw_drawers := false
var drawers := []

func _ready() -> void:
	base_transform = Transform2D(0, Vector2(unit_size.x, unit_size.y), 0, Vector2(0, -position.y))
	offset_transform = Transform2D(0, Vector2(1, 1), 0, Vector2())

var _time := 0.0
var _t_delta := 0.0

signal on_process

func _process(delta: float) -> void:
	_time += delta
	_t_delta = delta
	on_process.emit()
	queue_redraw()

signal on_draw

var _parent: SekaiControl = null

func _enter_tree() -> void:
	_parent = get_parent()
	_parent.unit_size_mod.connect(_on_unit_size_mod)
	unit_size = _parent.unit_size

func _on_unit_size_mod() -> void:
	unit_size = _parent.unit_size
	base_transform = Transform2D(0, Vector2(unit_size.x, unit_size.y), 0, Vector2(0, -position.y))

func _exit_tree() -> void:
	_parent.unit_size_mod.disconnect(_on_unit_size_mod)
	_parent = null

func _draw() -> void:
	offset_transform = Transform2D(0, Vector2(1, 1), 0, _parent._item_offset)
	pen_clear_transform()
	on_draw.emit()
	if need_draw_drawers: for drawer in drawers:
		drawer.call(null, null, null, self)

func get_time() -> float:
	return _time

func reset_time(time := 0.0) -> void:
	_time = time

func get_delta_time() -> float:
	return _t_delta

func set_y(y: float) -> void:
	if y != position.y:
		position.y = y
		base_transform = Transform2D(0, Vector2(unit_size.x, unit_size.y), 0, Vector2(0, -position.y))

func set_offset(pos: Vector2) -> void:
	offset_transform = Transform2D(0, Vector2(1, 1), 0, pos)

func rect3_to_rect2(rect: AABB) -> Rect2:
	return Rect2(
		rect.position.x,
		rect.position.y - rect.position.z * ratio_yz,
		rect.size.x,
		rect.size.y + rect.size.z * ratio_yz,
	)

func pen_draw_texture(texture: Texture2D, rect: Rect2, pmodulate := Color(1, 1, 1, 1)) -> void:
	draw_texture_rect(texture, rect, false, pmodulate)

func pen_draw_texture_region(texture: Texture2D, rect: Rect2, region: Rect2, pmodulate := Color(1, 1, 1, 1)) -> void:
	draw_texture_rect_region(texture, rect, region, pmodulate)

func pen_set_transform(ptransform: Transform2D) -> void:
	draw_set_transform_matrix(base_transform * offset_transform * ptransform)

func pen_clear_transform() -> void:
	draw_set_transform_matrix(base_transform * offset_transform)
