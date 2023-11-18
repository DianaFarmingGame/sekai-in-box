class_name SekaiPen

var cav: CanvasItem
var base_transform: Transform2D

func _init(pcav: CanvasItem, transform: Transform2D):
	cav = pcav
	base_transform = transform
	clear_transform()

func draw_texture(texture: Texture2D, rect: Rect2, modulate := Color(1, 1, 1, 1)) -> void:
	texture.draw_rect(cav, rect, false, modulate)

func draw_texture_region(texture: Texture2D, rect: Rect2, region: Rect2, modulate := Color(1, 1, 1, 1)) -> void:
	texture.draw_rect_region(cav, rect, region, modulate)

func set_transform(position: Vector2, rotation := 0.0, scale := Vector2(1, 1)) -> void:
	cav.draw_set_transform_matrix(base_transform * Transform2D(rotation, scale, 0, position))

func clear_transform() -> void:
	cav.draw_set_transform_matrix(base_transform)
