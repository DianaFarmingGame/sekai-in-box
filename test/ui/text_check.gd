extends TextureRect

var yes_func : Callable
var no_func: Callable

func _ready():
	hide()

func _on_yes_pressed():
	yes_func.call()
	hide()

func _on_no_pressed():
	no_func.call()
	hide()

func set_text(value: String):
	$Label.text = value
