class_name UI合成台 extends MonoTrait

var id := &"UI合成台"
var requires := [&"ui", &"有背包"]

var props := {
	#
	# 方法
	#
	
	# 打开合成台界面的主视图
	&"craft/toggle": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
		var node = this.applymRSUY(ctx, &"ui/get", [ctrl, &"craft"])
		if node == null:
			await this.applymRSU(ctx, &"ui/toggle", [ctrl, &"craft"])
			this.emitmRSUY(ctx, &"control/block")
		elif node.visible == false:
			node.show()
			this.emitmRSUY(ctx, &"control/block")
		else:
			node.hide()
			this.emitc(ctx, &"on_craft_closed")
			this.emitmRSUY(ctx, &"control/unblock")
		#if await this.applymRSU(ctx, &"ui/toggle", [ctrl, &"craft"]) != null:
			#this.emitmRSUY(ctx, &"control/block")
		#else:
			#this.emitc(ctx, &"on_craft_closed")
			#this.emitmRSUY(ctx, &"control/unblock")
		pass,
		
	# 渲染合成台
	&"craft/update": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, target: Mono) -> void:
		if target.getp(&"contains") is Array:
			var node = this.applymRSUY(ctx, &"ui/get", [ctrl, &"craft"])
			node.this = this
			node.target = target
			node.context = ctx
			node.control = ctrl
			node.update_inventory()
			node.update_view()
		pass,
	
	#
	# 信号
	#
	
	# 当物品界面的主视图被关闭时触发
	&"on_craft_closed": Prop.Stack(),
	
	
	
	#--------------------------------------------------------------------------#
	&"ui_data": {
		&"craft": preload("合成台/craft.tscn"),
	},
}
