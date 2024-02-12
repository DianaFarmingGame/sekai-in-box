extends Control

var param: Dictionary

signal finished

func _ready() -> void:
	if param.get(&"name") != null:
		%Name.text = param[&"name"]
	else:
		%Name.visible = false
	if param.get(&"avatar") != null:
		%Avatar.texture = param[&"avatar"]
	else:
		%Avatar.visible = false
	%Dialog.text = param.get(&"text")

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		finished.emit()
	accept_event()
