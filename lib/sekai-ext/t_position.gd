class_name TPosition extends MonoTrait

var id := &"position"

var props := {
	&"position": Vector3(0, 0, 0),
	&"size": Vector3(1, 1, 1),
	&"on_init": Prop.puts({
		&"-99:position": func (_sekai, this: Mono) -> void:
			this.position = this.getp(&"position")
			pass,
	}),
	&"on_store": Prop.puts({
		&"-99:position": func (_sekai, this: Mono) -> void:
			if this.getp(&"position") != this.position:
				this.setp(&"position", this.position)
			pass,
	}),
	&"on_restore": Prop.puts({
		&"-99:position": func (_sekai, this: Mono) -> void:
			this.position = this.getp(&"position")
			pass,
	}),
}
