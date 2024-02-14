extends Control

var param: Dictionary

signal finished

func _ready() -> void:
	var vname = param.get(&"name")
	if vname != null and vname.length() > 0:
		%Name.text = param[&"name"]
	else:
		%Name.visible = false
	if param.get(&"avatar") != null:
		%Avatar.texture = param[&"avatar"]
	else:
		%Avatar.visible = false
	%Dialog.text = param.get(&"text")

func _on_texture_rect_gui_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		finished.emit()
	accept_event()
