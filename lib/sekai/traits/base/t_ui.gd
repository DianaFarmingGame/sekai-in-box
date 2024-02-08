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
	&"ui/enable": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, uid: StringName) -> void:
		if ctrl.is_sub: return
		var acts := this.getpBR(&"act_ui").duplicate() as Array
		if not this.getpBR(&"ui_nodes").get(ctrl, {}).has(uid):
			await this.applycRSU(ctx, &"ui/add", [ctrl, uid])
			if not acts.has(uid): acts.append(uid)
			this.setpB(&"act_ui", acts),
	
	# 禁用 UI
	&"ui/disable": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, uid: StringName) -> void:
		if ctrl.is_sub: return
		var acts := this.getpBR(&"act_ui").duplicate() as Array
		if this.getpBR(&"ui_nodes").get(ctrl, {}).has(uid):
			await this.applycRSU(ctx, &"ui/remove", [ctrl, uid])
			acts.erase(uid)
			this.setpB(&"act_ui", acts),
	
	# 开关 UI
	&"ui/toggle": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, uid: StringName) -> void:
		if ctrl.is_sub: return
		var acts := this.getpBR(&"act_ui").duplicate() as Array
		if this.getpBR(&"ui_nodes").get(ctrl, {}).has(uid):
			await this.applycRSU(ctx, &"ui/remove", [ctrl, uid])
			acts.erase(uid)
		else:
			await this.applycRSU(ctx, &"ui/add", [ctrl, uid])
			if not acts.has(uid): acts.append(uid)
		this.setpB(&"act_ui", acts),
	
	
	
	#--------------------------------------------------------------------------#
	&"ui_nodes": {},
	&"ui/add": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, uid: StringName) -> void:
		if ctrl.is_sub: return
		var data := this.getpBR(&"ui_data") as Dictionary
		var nodes := this.getpBD(&"ui_nodes", {}) as Dictionary
		var list := nodes.get(nodes, {}) as Dictionary
		var node := TUI.make_ui(ctx, this, ctrl, data[uid])
		list[uid] = node
		nodes[ctrl] = list
		this.setpB(&"ui_nodes", nodes)
		ctrl.add_child(node),
	&"ui/remove": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, uid: StringName) -> void:
		if ctrl.is_sub: return
		var list := this.getpB(&"ui_nodes")[ctrl] as Dictionary
		var node := list[uid] as Node
		ctrl.remove_child(node)
		node.free()
		list.erase(uid),
	&"on_target_set": Prop.puts({
		&"0:ui": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
			if ctrl.is_sub: return
			var acts := this.getpBR(&"act_ui") as Array
			var data := this.getpBR(&"ui_data") as Dictionary
			var nodes := this.getpBD(&"ui_nodes", {}) as Dictionary
			var list := {}
			for uid in acts:
				var node := TUI.make_ui(ctx, this, ctrl, data[uid])
				list[uid] = node
			nodes[ctrl] = list
			this.setpB(&"ui_nodes", nodes)
			for node in list.values():
				ctrl.add_child(node),
	}),
	&"on_target_unset": Prop.puts({
		&"0:ui": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
			if ctrl.is_sub: return
			var nodes := this.getpBD(&"ui_nodes", {}) as Dictionary
			var list := nodes[ctrl] as Dictionary
			for node in list.values():
				ctrl.remove_child(node)
				node.free()
			nodes.erase(ctrl),
	}),
	&"on_input": Prop.puts({
		&"0:ui_debug": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, sets: InputSet) -> void:
			if ctrl.is_sub: return
			if sets.pressings.has(&"toggle_debug_ui"):
				await this.applycRSU(ctx, &"ui/toggle", [ctrl, &"debug"]),
	}),
}

static func make_ui(ctx: LisperContext, this: Mono, ctrl: SekaiControl, ui: PackedScene) -> Node:
	var node := ui.instantiate()
	if node.get_property_list().any(func (opt): return opt[&"name"] == &"this"):
		node.this = this
	if node.get_property_list().any(func (opt): return opt[&"name"] == &"context"):
		node.context = ctx
	if node.get_property_list().any(func (opt): return opt[&"name"] == &"control"):
		node.control = ctrl
	return node
