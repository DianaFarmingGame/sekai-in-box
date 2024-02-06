class_name TDrawable extends MonoTrait

var id := &"drawable"
var requires := [&"with_layer", &"position"]

var props := {
	&"on_draw": Prop.Stack(),
	
	&"on_control_enter": Prop.puts({
		&"1:drawable": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
			var item := this.getpB(&"layer") as SekaiItem
			item.set_y(this.position.y + floorf(this.position.z) * 64)
			item.on_draw.connect(func ():
				this.callmR(ctx, &"on_draw", item)
			),
	}),
	&"on_position_mod": Prop.puts({
		&"0:drawable": func (ctx: LisperContext, this: Mono) -> void:
			var item := this.getpB(&"layer") as SekaiItem
			item.set_y(this.position.y + floorf(this.position.z) * 64),
	}),
}
