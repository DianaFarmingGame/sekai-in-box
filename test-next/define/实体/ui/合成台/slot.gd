extends TextureRect

var item_texture: Texture2D:
	set(v):
		$TextureRect.texture = v
		
var label: String:
	set(v):
		$Label.text = v

func clear() -> void:
	$TextureRect.texture = null
	$Label.text = ""
