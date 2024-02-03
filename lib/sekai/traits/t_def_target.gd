class_name TDefTarget extends MonoTrait

var id := &"def_target"

var props := {
	&"on_ready": Prop.puts({
		&"0:def_target": func (ctx: LisperContext, this: Mono) -> void:
			sekai.gikou.setp(&"def_target", this),
	}),
}
