class_name MonoEntity extends Mono

func draw() -> void:
	super.draw()
	if get_prop(&"visible"):
		get_method(&"draw").call(sekai, self)
