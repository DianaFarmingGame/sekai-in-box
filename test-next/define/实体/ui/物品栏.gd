class_name UI物品栏 extends MonoTrait

var id := &"UI物品栏"
var requires := [&"ui", &"有背包"]

const View := preload("物品栏/view.tscn")

var props := {
	#
	# 方法
	#
	
	# 打开某个容器的物品界面
	&"inventory/open": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, target: Mono) -> void:
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
	
	
	
	#--------------------------------------------------------------------------#
	&"ui_data": {
		&"inventory": preload("物品栏/main.tscn"),
	},
}
