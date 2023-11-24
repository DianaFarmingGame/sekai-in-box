class_name SekaiItem extends Node2D

var base_transform: Transform2D
var unit_size: Vector2

func _init() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

func _ready() -> void:
	base_transform = Transform2D(0, unit_size, 0, Vector2(0, -position.y))

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
	position.y = y
	base_transform = Transform2D(0, unit_size, 0, Vector2(0, -position.y))

func pen_draw_texture(texture: Texture2D, rect: Rect2, pmodulate := Color(1, 1, 1, 1)) -> void:
	draw_texture_rect(texture, rect, false, pmodulate)

func pen_draw_texture_region(texture: Texture2D, rect: Rect2, region: Rect2, pmodulate := Color(1, 1, 1, 1)) -> void:
	draw_texture_rect_region(texture, rect, region, pmodulate)

func pen_set_transform(pposition: Vector2, protation := 0.0, pscale := Vector2(1, 1)) -> void:
	draw_set_transform_matrix(base_transform * Transform2D(protation, pscale, 0, pposition))

func pen_clear_transform() -> void:
	draw_set_transform_matrix(base_transform)
