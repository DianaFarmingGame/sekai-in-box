extends Control

var label: String:
	set(v):
		%Label.text = v

var texture: Texture2D:
	set(v):
		%Texture.texture = v
		%TextureShadow.texture = v
