class_name TDrawable extends MonoTrait

var id := &"drawable"
var requires := [&"with_sekai_item"]

var props := {
	&"on_draw": Prop.Stack(),
	&"draw_listener": null,
	
	&"on_control_enter": Prop.puts({
		&"1:drawable": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
			var item := this.getpB(&"sekai_item") as SekaiItem
			var draw_listener := func ():
				this.callmR(ctx, &"on_draw", item)
			item.on_draw.connect(draw_listener)
			this.setpB(&"draw_listener", draw_listener),
	}),
	&"on_control_exit": Prop.puts({
		&"-1:drawable": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
			var item := this.getpB(&"sekai_item") as SekaiItem
			var draw_listener := this.getpB(&"draw_listener") as Callable
			this.setpB(&"draw_listener", null)
			item.on_draw.disconnect(draw_listener),
	}),
}
