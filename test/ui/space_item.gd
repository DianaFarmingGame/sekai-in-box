extends TextureRect

var picture: Resource : set = picture_change
var num: int : set = num_change

func _ready():
	self.texture = picture
	$num.text = str(num)
	$Descrip.hide()
	
func picture_change(value):
	picture = value
	self.texture = value
	
func num_change(value):
	num = value
	$num.text = str(num)

func _get_drag_data(_position):
	var item_index = get_parent().get_index()
	var data = {
			"space": get_parent().get_parent().get_parent().space_name,
			"index": item_index,
		}
	var drag_preview = TextureRect.new()
	drag_preview.texture = picture
	set_drag_preview(drag_preview)
	
	return data

func _input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			var mouse_position = get_global_mouse_position()
			if mouse_position.distance_to(global_position) < 50 and mouse_position.x > global_position.x and mouse_position.y > global_position.y: # 右下角
				$Descrip.show()
			else:
				$Descrip.hide()
