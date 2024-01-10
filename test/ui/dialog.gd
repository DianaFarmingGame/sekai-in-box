extends Control

func set_character_name(value: String):
	$TextureRect/name.text = value
	
func set_content(value: String):
	$TextureRect/content.text = value
	
func set_character_texture(value: Texture):
	$TextureRect/character.texture = value

func set_visiable_content(value: int):
	$TextureRect/content.visible_characters = value
	
func get_visiable_character_count():
	return $TextureRect/content.visible_characters
	
func get_total_character_count():
	return $TextureRect/content.get_total_character_count()
