class_name TaskButton extends Button

signal press(desc)

var desc: String

func _ready():
	self.pressed.connect(self._on_pressed)

func _on_pressed():
	emit_signal("press", desc)
