class_name TaskButton extends Button

signal press(desc,rewards)

var desc: String
var rewards: Dictionary

func _ready():
	self.pressed.connect(self._on_pressed)

func _on_pressed():
	emit_signal("press", desc, rewards)
