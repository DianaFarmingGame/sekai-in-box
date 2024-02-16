class_name UI物品栏 extends MonoTrait

var id := &"UI物品栏"
var requires := [&"ui", &"有背包"]

const View := preload("物品栏/view.tscn")

var props := {
	#
	# 方法
	#
	
	# 打开物品界面的主视图
	&"inventory/toggle": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
		if await this.applymRSU(ctx, &"ui/toggle", [ctrl, &"inventory"]) != null:
			this.emitmRSUY(ctx, &"control/block")
		else:
			this.emitc(ctx, &"on_inventory_closed")
			this.emitmRSUY(ctx, &"control/unblock")
		var node = this.applymRSUY(ctx, &"ui/get", [ctrl, &"slots"])
		if node != null:
			node.can_modify = this.applymRSUY(ctx, &"ui/get", [ctrl, &"inventory"]) != null
		pass,
	
	# 打开某个容器的物品界面 (需要主视图为开启状态)
	&"inventory/add": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, target: Mono) -> void:
		if target.getp(&"contains") is Array:
			var node = this.applymRSUY(ctx, &"ui/get", [ctrl, &"inventory"])
			if node != null:
				var view := View.instantiate()
				view.this = this
				view.target = target
				view.context = ctx
				view.control = ctrl
				node.add_child(view)
		pass,
	
	
	
	#
	# 信号
	#
	
	# 当物品界面的主视图被关闭时触发
	&"on_inventory_closed": Prop.Stack(),
	
	
	
	#--------------------------------------------------------------------------#
	&"ui_data": {
		&"inventory": preload("物品栏/main.tscn"),
	},
}
