extends CanvasLayer

func set_character_name(value: String):
	$name.text = value
	
func set_content(value: String):
	$content.text = value
	
func set_character_texture(value: Texture):
	$character.texture = value
