class_name TControlCommon extends MonoTrait

var id := &"control_common"
var requires := [&"input", &"pick"]

var props := {
	#
	# 配置
	#
	
	# 是否允许接收一般操作 (菜单操作除外)
	&"can_common_action": true,
	
	
	
	#
	# 信号
	#
	
	# 切换快捷槽
	# @params: SekaiControl, -1: 光标后退 | 1: 光标前进
	&"on_slot_switch": Prop.Stack(),
	
	# 选择快捷槽
	# @params: SekaiControl, int<0~4>: 选择槽位的 index
	&"on_slot_select": Prop.Stack(),
	
	# 开关物品栏
	# @params: SekaiControl
	&"on_inventory_toggle": Prop.Stack(),
	
	# 进行主操作
	# @params: SekaiControl, Mono | null: 可能选取到的对象, InputSet
	&"on_action_primary": Prop.Stack(),
	
	# 进行次操作
	# @params: SekaiControl, Mono | null: 可能选取到的对象, InputSet
	&"on_action_secondary": Prop.Stack(),
	
	
	
	#--------------------------------------------------------------------------#
	&"on_input": Prop.puts({
		&"0:common_actions": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, sets: InputSet) -> void:
			if this.getp(&"can_common_action"):
				for act in sets.pressings.keys():
					match act:
						&"slot_prev": await this.applyc(ctx, &"on_slot_switch", [ctrl, -1])
						&"slot_next": await this.applyc(ctx, &"on_slot_switch", [ctrl, 1])
						&"slot_1": await this.applyc(ctx, &"on_slot_select", [ctrl, 0])
						&"slot_2": await this.applyc(ctx, &"on_slot_select", [ctrl, 1])
						&"slot_3": await this.applyc(ctx, &"on_slot_select", [ctrl, 2])
						&"slot_4": await this.applyc(ctx, &"on_slot_select", [ctrl, 3])
						&"slot_5": await this.applyc(ctx, &"on_slot_select", [ctrl, 4])
						&"inventory_toggle": await this.applyc(ctx, &"on_inventory_toggle", [ctrl])
			pass,
	}),
	&"on_pick": Prop.puts({
		&"0:common_actions": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, pick: Variant, sets: InputSet) -> void:
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
