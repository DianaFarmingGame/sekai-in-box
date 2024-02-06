class_name TUI extends MonoTrait

var id := &"ui"
var requires := [&"input"]

var props := {
	#
	# 配置
	#
	
	# 激活的 UI 列表，使用 StringName 表示
	&"act_ui": Prop.Stack(),
	
	# UI 的数据
	&"ui_data": {
		&"debug": preload("debug_ui.tscn"),
	},
	
	
	
	#
	# 方法
	#
	
	# 启用 UI
	&"ui/enable": func (ctx: LisperContext, this: Mono, id: StringName) -> void:
		var acts := this.getp(&"act_ui") as Array
		if not acts.has(id):
			var data := this.getp(&"ui_data") as Dictionary,
			
	
	
	
	#--------------------------------------------------------------------------#
	&"ui_nodes": [],
	#&"ui/add": func (ctx: LisperContext, this: Mono, id: StringName) -> void:
		 #var data := this.getp(&"ui_data") as Dictionary
	&"on_control_enter": Prop.puts({
		&"0:ui": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
			var acts := this.getp(&"act_ui") as Array
			var data := this.getp(&"ui_data") as Dictionary
			var nodes := []
			for uid in acts:
				var ui := data[uid] as PackedScene
				var node := ui.instantiate()
				var need_this := node.get_property_list().any(func (opt): return opt[&"name"] == &"this")
				if need_this:
					node.this = this
				nodes.append(node)
			this.setp(&"ui_nodes", nodes)
			for node in nodes:
				ctrl.add_child(node),
	}),
	&"on_control_exit": Prop.puts({
		&"0:ui": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
			var nodes := this.getpD(&"ui_nodes", []) as Array
			for node in nodes:
				ctrl.remove_child(node)
				node.free(),
	}),
	&"on_input": Prop.puts({
		&"0:ui_debug": func (ctx: LisperContext, this: Mono, sets: InputSet) -> void:
			if sets.pressings.has(&"toggle_debug_ui"):
				this.pushs(&"act_ui", &"debug"),
	})
}
