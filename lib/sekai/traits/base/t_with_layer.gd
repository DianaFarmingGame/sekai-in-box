class_name TWithLayer extends MonoTrait
## 这个 Trait 用于提供在 Mono 进入 SekaiControl 时自动添加 SekaiItem 的功能
## 有一个默认的图层，但也可以请求额外的图层

var id := &"with_layer"

var props := {
	#
	# 配置
	#
	
	# 激活的额外图层列表，使用 StringName 表示
	&"act_layer": Prop.Stack(),
	
	#
	# 变量
	#
	
	# 默认图层
	&"layer": {},
	
	# 额外图层的映射表
	&"layer_data": {},
	
	# 图层的不透明度，只用于非发布场合
	&"layer_opacity": 1.0,
	
	
	
	#
	# 方法
	#
	
	# 启用图层
	&"layer/enable": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, uid: StringName) -> void:
		var acts := this.getpBR(&"act_layer").duplicate() as Array
		if not acts.has(uid):
			await this.applycRSU(ctx, &"layer/add", [ctrl, uid])
			acts.append(uid)
			this.setpB(&"act_layer", acts),
	
	# 禁用图层
	&"layer/disable": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, uid: StringName) -> void:
		var acts := this.getpBR(&"act_layer").duplicate() as Array
		if acts.has(uid):
			await this.applycRSU(ctx, &"layer/remove", [ctrl, uid])
			acts.erase(uid)
			this.setpB(&"act_layer", acts),
	
	# 开关图层
	&"layer/toggle": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, uid: StringName) -> void:
		var acts := this.getpBR(&"act_layer").duplicate() as Array
		if acts.has(uid):
			await this.applycRSU(ctx, &"layer/remove", [ctrl, uid])
			acts.erase(uid)
		else:
			await this.applycRSU(ctx, &"layer/add", [ctrl, uid])
			acts.append(uid)
		this.setpB(&"act_layer", acts),
			
	
	
	
	#--------------------------------------------------------------------------#
	&"layer/add": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, uid: StringName) -> void:
		var data := this.getpBD(&"layer_data", {}) as Dictionary
		var layers := data.get(ctrl, {}) as Dictionary
		var layer := SekaiItem.new()
		layers[uid] = layer
		data[ctrl] = layers
		this.setpB(&"layer_data", data)
		ctrl.add_child(layer),
	&"layer/remove": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, uid: StringName) -> void:
		var data := this.getpB(&"layer_data").get(ctrl, {}) as Dictionary
		var layer := data[uid] as SekaiItem
		ctrl.remove_child(layer)
		layer.free()
		data.erase(uid),
	&"on_control_enter": Prop.puts({
		&"0:with_layer": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
			var items := this.getpBD(&"layer", {}) as Dictionary
			var data := this.getpBD(&"layer_data", {}) as Dictionary
			var item := SekaiItem.new()
			var acts := this.getpBR(&"act_layer") as Array
			var layers := {}
			for uid in acts:
				var layer := SekaiItem.new()
				layers[uid] = layer
			items[ctrl] = item
			data[ctrl] = layers
			this.setpB(&"layer", items)
			this.setpB(&"layer_data", data)
			ctrl.add_child(item)
			for layer in layers.values():
				ctrl.add_child(layer),
	}),
	&"on_control_exit": Prop.puts({
		&"0:with_layer": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
			var items := this.getpBD(&"layer", {}) as Dictionary
			var data := this.getpBD(&"layer_data", {}) as Dictionary
			var item := items[ctrl] as SekaiItem
			var layers := data[ctrl] as Dictionary
			ctrl.remove_child(item)
			item.free()
			for layer in layers.values():
				ctrl.remove_child(layer)
				layer.free()
			items.erase(ctrl)
			data.erase(ctrl),
	}),
	&"on_layer_opacity": func (ctx: LisperContext, this: Mono, layer_opacity: float) -> float:
		var items := this.getpBD(&"layer", {}) as Dictionary
		var data := this.getpBD(&"layer_data", {}) as Dictionary
		for item in items.values():
			item.self_modulate = Color(1, 1, 1, layer_opacity)
		for layers in data.values():
			for layer in layers.values():
				layer.self_modulate = Color(1, 1, 1, layer_opacity)
		return layer_opacity,
}
