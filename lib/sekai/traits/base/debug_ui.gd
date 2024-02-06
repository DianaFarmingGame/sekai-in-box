extends Control

var this: Mono

func _process(delta: float) -> void:
	var msg := sekai.context.stringify_raw(this, 0, 0, false)
	$Position.text = str(this.position)
	$Label.text = msg
