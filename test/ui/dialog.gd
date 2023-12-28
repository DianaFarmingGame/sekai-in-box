extends CanvasLayer

func set_character_name(value: String):
	$name.text = value
	
func set_content(value: String):
	$content.text = value
	
func set_character_texture(value: Texture):
	$character.texture = value

func set_visiable_content(value: int):
	$content.visible_characters = value
	
func get_visiable_character_count():
	return $content.visible_characters
	
func get_total_character_count():
	return $content.get_total_character_count()
