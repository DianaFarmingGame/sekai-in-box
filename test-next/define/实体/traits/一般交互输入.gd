class_name 一般交互输入 extends MonoTrait

var id := &"一般交互输入"
var requires := [&"交互主体", &"主次行为输入", &"有快捷栏"]

var props := {
	&"on_action_primary": Prop.puts({
		&"0:一般交互": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, pick: Variant, sets: InputSet) -> void:
			var item = this.emitmRSUY(ctx, &"slot/get_current")
			if item != null:
				if await item.applymRSU(ctx, &"action/emit", [&"primary", ctrl, this, pick, sets]): return
			if pick != null:
				if await pick.applymRSU(ctx, &"action/emit", [&"primary", ctrl, this, pick, sets]): return
			pass,
	}),
	
	&"on_action_secondary": Prop.puts({
		&"0:一般交互": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, pick: Variant, sets: InputSet) -> void:
			var item = this.emitmRSUY(ctx, &"slot/get_current")
			if item != null:
				if await item.applymRSU(ctx, &"action/emit", [&"secondary", ctrl, this, pick, sets]): return
			if pick != null:
				if await pick.applymRSU(ctx, &"action/emit", [&"secondary", ctrl, this, pick, sets]): return
			pass,
	}),
}
