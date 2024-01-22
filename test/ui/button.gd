extends Button

class_name  CustomButton

signal press(index)

func _ready():
	self.pressed.connect(self._on_pressed)

func _on_pressed():
	emit_signal("press", get_index())
