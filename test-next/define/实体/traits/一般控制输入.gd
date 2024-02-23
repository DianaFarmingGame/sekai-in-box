class_name 一般控制输入 extends MonoTrait

var id := &"一般控制输入"
var requires := [&"input", &"可控制", &"有快捷栏", &"UI快捷栏", &"UI物品栏"]

var props := {
	#
	# 信号
	#
	
	# 切换快捷槽
	# @params: SekaiControl, -1: 光标后退 | 1: 光标前进
	&"on_slot_switch": Prop.Stack({
		&"0:一般控制": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, dir: int) -> void:
			await this.callmRSU(ctx, &"slot/move", dir),
	}),
	
	# 选择快捷槽
	# @params: SekaiControl, int<0~4>: 选择槽位的 index
	&"on_slot_select": Prop.Stack({
		&"0:一般控制": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, sel: int) -> void:
			await this.setpBW(ctx, &"cur_slot", sel),
	}),
	
	# 开关物品栏
	# @params: SekaiControl
	&"on_inventory_toggle": Prop.Stack({
		&"0:一般控制": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
			print("open")
			await this.callmRSU(ctx, &"inventory/toggle", ctrl),
	}),
	
	
	
	#--------------------------------------------------------------------------#
	&"on_input": Prop.puts({
		&"0:一般控制": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, sets: InputSet) -> void:
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
}
