class_name SekaiItem extends Node2D

var base_transform: Transform2D
var unit_size: Vector3:
	set(v):
		unit_size = v
		ratio_yz = v.y / v.z
var ratio_yz := 1.0

func _ready() -> void:
	base_transform = Transform2D(0, Vector2(unit_size.x, unit_size.y), 0, Vector2(0, -position.y))

#func _exit_tree() -> void:
#	print("SekaiItem exit")

var _time := 0.0
var _t_delta := 0.0

signal on_process

func _process(delta: float) -> void:
	_time += delta
	_t_delta = delta
	on_process.emit()
	queue_redraw()

signal on_draw

func _draw() -> void:
	pen_clear_transform()
	on_draw.emit()

func get_time() -> float:
	return _time

func get_delta_time() -> float:
	return _t_delta

func set_y(y: float) -> void:
	if y != position.y:
		position.y = y
		base_transform = Transform2D(0, Vector2(unit_size.x, unit_size.y), 0, Vector2(0, -position.y))

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
	draw_set_transform_matrix(base_transform * ptransform)

func pen_clear_transform() -> void:
	draw_set_transform_matrix(base_transform)
