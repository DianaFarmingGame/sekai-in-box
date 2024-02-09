class_name TDrawable extends MonoTrait

var id := &"drawable"
var requires := [&"with_layer", &"position"]

var props := {
	&"on_draw": Prop.Stack(),
	&"on_draw_debug": Prop.Stack(),
	
	&"act_layer": Prop.pushs([&"debug_draw"] if ProjectSettings.get_setting(&"sekai/debug_draw") else []),
	&"on_control_enter": Prop.puts({
		&"1:drawable": TDrawable.handle_control_enter,
		&"2:debug_drawable": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
			var layers := this.getpB(&"layer_data")[ctrl] as Dictionary
			var item := layers[&"debug_draw"] as SekaiItem
			item.set_y(this.position.y + floorf(this.position.z) * 64 + 4096)
			item.on_draw.connect(func ():
				this.applymR(ctx, &"on_draw_debug", [ctrl, item])
			),
	} if ProjectSettings.get_setting(&"sekai/debug_draw") else {
		&"1:drawable": TDrawable.handle_control_enter,
	}),
	&"on_position_mod": Prop.puts({
		&"0:drawable": TDrawable.handle_position_mod,
		&"0:debug_drawable": func (ctx: LisperContext, this: Mono) -> void:
			var data := this.getpB(&"layer_data") as Dictionary
			for layers in data.values():
				var item := layers[&"debug_draw"] as SekaiItem
				item.set_y(this.position.y + floorf(this.position.z) * 64 + 4096),
	} if ProjectSettings.get_setting(&"sekai/debug_draw") else {
		&"0:drawable": TDrawable.handle_position_mod,
	}),
}

static func handle_control_enter(ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
	var item := this.getpB(&"layer")[ctrl] as SekaiItem
	item.set_y(this.position.y + floorf(this.position.z) * 64)
	item.on_draw.connect(func ():
		this.applym(ctx, &"on_draw", [ctrl, item])
	)

static func handle_position_mod(ctx: LisperContext, this: Mono) -> void:
	var items := this.getpB(&"layer") as Dictionary
	for item in items.values():
		item.set_y(this.position.y + floorf(this.position.z) * 64)
