extends TextureButton

@onready var scroll_container = $"../list"
@export var y_max: int
@export var y_min: int

var is_dragging = false
var grab_offset = Vector2()
#var proportion
#
#func _ready():
	#proportion = scroll_container.get_v_scroll_bar().max_value / (y_max - y_min)
#
#func update_proportion():
	#print(scroll_container.get_v_scroll_bar().max_value)
	#proportion = scroll_container.get_v_scroll_bar().max_value / (y_max - y_min)

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_position = get_global_mouse_position()
			if mouse_position.distance_to(global_position) < 50: # 检查鼠标是否在对象附近
				is_dragging = true
				grab_offset = position.y - mouse_position.y # 记录鼠标与对象 Y 轴位置之间的偏移
		elif event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			is_dragging = false
	elif event is InputEventMouseMotion and is_dragging:
		position.y = clamp(get_global_mouse_position().y + grab_offset, y_min, y_max)
		var proportion = scroll_container.get_v_scroll_bar().max_value / (y_max - y_min)
		scroll_container.scroll_vertical = (position.y - y_min) * proportion


