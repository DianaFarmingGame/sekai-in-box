class_name TCommonActions extends MonoTrait

var id := &"common_inputs"
var requires := [&"input"]

var props := {
	&"activate": true,

	&"on_input": Prop.puts({
		&"0:switch_item": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, sets: InputSet) -> void:
			if this.getp(&"activate"):
				var choose := 0
				if sets.pressings.has(&"last_item"):
					choose = 1
				elif sets.pressings.has(&"next_item"):
					choose = -1

				if choose != 0:
					this.applyc(ctx, &"on_switch_item", [ctrl, choose])
				
			pass,

		&"0:choose_item": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, sets: InputSet) -> void:
			if this.getp(&"activate"):
				var number := -1
				if sets.pressings.has(&"slot_1"):
					number = 0
				elif sets.pressings.has(&"slot_2"):
					number = 1
				elif sets.pressings.has(&"slot_3"):
					number = 2
				elif sets.pressings.has(&"slot_4"):
					number = 3
				elif sets.pressings.has(&"slot_5"):
					number = 4
				elif sets.pressings.has(&"slot_6"):
					number = 5
				elif sets.pressings.has(&"slot_7"):
					number = 6
				elif sets.pressings.has(&"slot_8"):
					number = 7
				elif sets.pressings.has(&"slot_9"):
					number = 8
				
				if number != -1:
					this.applyc(ctx, &"on_choose_item", [ctrl, number])
			pass,

		&"0:open_inventory": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, sets: InputSet) -> void:
			if this.getp(&"activate"):
				if sets.pressings.has(&"open_inventory"):
					this.applyc(ctx, &"on_open_inventory", [ctrl])
			pass,
				
		&"0:open_menu": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, sets: InputSet) -> void:
			if sets.pressings.has(&"open_menu"):
				this.applyc(ctx, &"on_open_menu", [ctrl])
			pass,
	
		# &"0:open_map": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, sets: InputSet) -> void:
		# 	if sets.pressings.has(&"open_map"):
		# 		this.applyc(ctx, &"on_open_map", [ctrl])
		# 	pass,
	}),

	&"on_pick": Prop.puts({
		&"0:main_function": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, pick: Mono, sets: InputSet) -> void:
			if this.getp(&"activate"):
				if sets.pressings.has(&"main_click"):
					this.applyc(ctx, &"on_main_click", [ctrl, pick, sets])
			pass,

		&"0:sub_function": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, pick: Mono, sets: InputSet) -> void:
			if this.getp(&"activate"):
				if sets.pressings.has(&"sub_click"):
					this.applyc(ctx, &"on_sub_click", [ctrl, pick, sets])
			pass,
	}),
}