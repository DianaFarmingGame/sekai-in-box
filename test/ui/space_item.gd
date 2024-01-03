extends Control

class_name Itema

var picture: Resource : set = picture_change
var num: int : set = num_change

func _ready():
	$picture.texture = picture
	$num.text = str(num)
	
func picture_change(value):
	picture = value
	$picture.texture = value
	
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
