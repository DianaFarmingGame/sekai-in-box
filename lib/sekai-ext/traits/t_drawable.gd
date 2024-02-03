class_name TDrawable extends MonoTrait

var id := &"drawable"
var requires := [&"with_sekai_item", &"position"]

var props := {
	&"on_draw": Prop.Stack(),
	
	&"on_control_enter": Prop.puts({
		&"1:drawable": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
			var item := this.getpB(&"sekai_item") as SekaiItem
			item.set_y(this.position.y + floorf(this.position.z) * 64)
			item.on_draw.connect(func ():
				this.callmR(ctx, &"on_draw", item)
			),
	}),
	&"on_move": Prop.puts({
		&"99:drawable": func (ctx: LisperContext, this: Mono) -> void:
			var item := this.getpB(&"sekai_item") as SekaiItem
			item.set_y(this.position.y + floorf(this.position.z) * 64),
	}),
}
