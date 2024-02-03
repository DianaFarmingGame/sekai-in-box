class_name TDrawable extends MonoTrait

var id := &"drawable"
var requires := [&"with_sekai_item"]

var props := {
	&"on_draw": Prop.Stack(),
	
	&"on_control_enter": Prop.puts({
		&"1:drawable": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
			var item := this.getpB(&"sekai_item") as SekaiItem
			item.on_draw.connect(func ():
				this.callmR(ctx, &"on_draw", item)
			),
	}),
}
