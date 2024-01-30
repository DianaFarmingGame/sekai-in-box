class_name TPosition extends MonoTrait

var id := &"position"

var props := {
	&"position": Vector3(0, 0, 0),
	&"size": Vector3(1, 1, 1),
	&"on_move": Prop.Stack([]),
	
	&"position_set": func (this: Mono, pos: Variant) -> void:
		if pos is Vector3:
			this.position = pos
		else:
			this.position = Vector3(pos.x, pos.y, this.position.z)
		this.emitm(&"on_move"),
	&"position_move": func (this: Mono, offset: Variant) -> void:
		if offset is Vector3:
			this.position += offset
		else:
			this.position += Vector3(offset.x, offset.y, 0)
		this.emitm(&"on_move"),
	&"on_init": Prop.puts({
		&"-99:position": func (this: Mono) -> void:
			this.position = this.getp(&"position")
			pass,
	}),
	&"on_store": Prop.puts({
		&"-99:position": func (this: Mono) -> void:
			if this.getp(&"position") != this.position:
				this.setp(&"position", this.position)
			pass,
	}),
	&"on_restore": Prop.puts({
		&"-99:position": func (this: Mono) -> void:
			this.position = this.getp(&"position")
			pass,
	}),
}
