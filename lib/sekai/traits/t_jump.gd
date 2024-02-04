class_name TJump extends MonoTrait

var id := &"jump"
var requires := [&"position"]

var props := {
	&"gravity": 9.8,
	&"initial_velocity": 5,
	&"init_z": 0,
	&"jump_time": 0,
	&"on_jump": false,
	&"on_input_action": Prop.puts({
		&"1:jump": func (ctx: LisperContext, this: Mono, _all, press: Dictionary, _release) -> void:
			if press.has(&"dialog_confirm"):
				this.setp(&"init_z", this.position.z)
				this.setp(&"on_jump", true)
				this.setp(&"jump_time", 0),
	}),
	&"on_process": Prop.puts({
		&"1:jump": func (ctx: LisperContext, this: Mono) -> void:
			if this.getp(&"on_jump"):
				var v = this.getp(&"initial_velocity")
				var g = this.getp(&"gravity")
				var init_z = this.getp(&"init_z")
				var delta := this.item.get_delta_time() as float
				var t = this.getp(&"jump_time") + delta
				this.setp(&"jump_time", t)
				var z = init_z + v * t - 0.5 * g * t * t
				if z < init_z:
					this.position.z = init_z
					this.setp(&"on_jump", false)
				else:
					this.position.z = z,
	}),
}
