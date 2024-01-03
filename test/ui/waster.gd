extends Control

func _can_drop_data(_position, data):
	return data is Dictionary and data.has("index")
	
func _drop_data(_position, data):
	var from_space = data["space"]
	var from_index = data["index"]
	$"..".remove_item.emit(from_space,from_index)
		
func _on_mouse_entered():
	$AnimatedSprite2D.play()

func _on_mouse_exited():
	$AnimatedSprite2D.stop()
