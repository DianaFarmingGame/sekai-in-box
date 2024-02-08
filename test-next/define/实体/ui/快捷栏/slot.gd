extends Control

var shortcut_label: String:
	set(v):
		%ShortcutLabel.text = v

var active: bool:
	set(v):
		if v:
			custom_minimum_size = Vector2(64, 64)
			#%ShortcutLabel.visible = false
		else:
			custom_minimum_size = Vector2(48, 48)

var texture: Texture2D:
	set(v):
		%Texture.texture = v
		%TextureShadow.texture = v
