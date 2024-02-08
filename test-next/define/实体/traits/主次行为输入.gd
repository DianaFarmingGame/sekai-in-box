class_name 主次行为输入 extends MonoTrait

var id := &"主次行为输入"
var requires := [&"pick", &"可控制"]

var props := {
	#
	# 信号
	#
	
	# 进行主操作
	# @params: SekaiControl, Mono | null: 可能选取到的对象, InputSet
	&"on_action_primary": Prop.Stack(),
	
	# 进行次操作
	# @params: SekaiControl, Mono | null: 可能选取到的对象, InputSet
	&"on_action_secondary": Prop.Stack(),
	
	
	
	#--------------------------------------------------------------------------#
	&"on_pick": Prop.puts({
		&"0:一般控制": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, pick: Variant, sets: InputSet) -> void:
			if this.getp(&"can_common_action"):
				for act in sets.pressings.keys():
					match act:
						&"action_primary":
							await this.applyc(ctx, &"on_action_primary", [ctrl, pick, sets])
						&"action_secondary":
							await this.applyc(ctx, &"on_action_secondary", [ctrl, pick, sets])
			pass,
	}),
}
