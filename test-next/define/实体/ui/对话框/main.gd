extends Control

var param: Dictionary

signal finished

func _ready() -> void:
	if param.has(&"name"):
		%Name.text = param[&"name"]
	%Dialog.text = param.get(&"text")

func _on_panel_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		finished.emit()
	accept_event()
