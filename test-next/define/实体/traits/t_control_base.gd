class_name TControlBase extends MonoTrait

var id := &"control_base"
var requires := [&"input"]

var props := {
	#
	# 信号
	#
	
	# 开关菜单
	# @params: SekaiControl
	&"on_menu_toggle": Prop.Stack(),
	
	
	
	#--------------------------------------------------------------------------#
	&"on_input": Prop.puts({
		&"0:menu_toggle": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, sets: InputSet) -> void:
			if sets.pressings.has(&"menu_toggle"):
				this.applyc(ctx, &"on_menu_toggle", [ctrl])
			pass,
	}),
}
