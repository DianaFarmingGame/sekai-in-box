extends TextureRect

func _ready():
	hide()

func _input(event):
	if event.is_action_pressed("menu"):
		visible = !visible
