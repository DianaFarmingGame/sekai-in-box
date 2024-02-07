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
	&"layer": null,
	
	# 额外图层的映射表
	&"layer_data": {},
	
	# 图层的不透明度，只用于非发布场合
	&"layer_opacity": 1.0,
	
	
	
	#
	# 方法
	#
	
	# 启用图层
	&"layer/enable": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, uid: StringName) -> void:
		var acts := this.getpBR(&"act_layer") as Array
		if not acts.has(uid):
			await this.applycRSU(ctx, &"layer/add", [ctrl, uid])
			acts.append(uid)
			this.setpB(&"act_layer", acts),
	
	# 禁用图层
	&"layer/disable": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, uid: StringName) -> void:
		var acts := this.getpBR(&"act_layer") as Array
		if acts.has(uid):
			await this.applycRSU(ctx, &"layer/remove", [ctrl, uid])
			acts.erase(uid)
			this.setpB(&"act_layer", acts),
	
	# 开关图层
	&"layer/toggle": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, uid: StringName) -> void:
		var acts := this.getpBR(&"act_layer") as Array
		if acts.has(uid):
			await this.applycRSU(ctx, &"layer/remove", [ctrl, uid])
			acts.erase(uid)
		else:
			await this.applycRSU(ctx, &"layer/add", [ctrl, uid])
			acts.append(uid)
		this.setpB(&"act_layer", acts),
			
	
	
	
	#--------------------------------------------------------------------------#
	&"layer/add": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, uid: StringName) -> void:
		var data := this.getpBR(&"layer_data") as Dictionary
		var layer := SekaiItem.new()
		data[uid] = layer
		this.setpB(&"layer_data", data)
		ctrl.add_child(layer),
	&"layer/remove": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, uid: StringName) -> void:
		var data := this.getpB(&"layer_data") as Dictionary
		var layer := data[uid] as SekaiItem
		ctrl.remove_child(layer)
		layer.free()
		data.erase(uid)
		this.setpB(&"layer_data", data),
	&"on_control_enter": Prop.puts({
		&"0:with_layer": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
			var item := SekaiItem.new()
			var acts := this.getpBR(&"act_layer") as Array
			var layers := {}
			for uid in acts:
				var layer := SekaiItem.new()
				layers[uid] = layer
			this.setpB(&"layer", item)
			this.setpB(&"layer_data", layers)
			ctrl.add_child(item)
			for layer in layers.values():
				ctrl.add_child(layer),
	}),
	&"on_control_exit": Prop.puts({
		&"0:with_layer": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
			var item := this.getpBR(&"layer") as SekaiItem
			var data := this.getpBR(&"layer_data") as Dictionary
			ctrl.remove_child(item)
			item.free()
			for layer in data.values():
				ctrl.remove_child(layer)
				layer.free()
			this.setpB(&"layer", null)
			this.setpB(&"layer_data", {}),
	}),
	&"on_layer_opacity": func (ctx: LisperContext, this: Mono, layer_opacity: float) -> float:
		var item := this.getpBR(&"layer") as SekaiItem
		var data := this.getpBR(&"layer_data") as Dictionary
		item.self_modulate = Color(1, 1, 1, layer_opacity)
		for layer in data.values():
			layer.self_modulate = Color(1, 1, 1, layer_opacity)
		return layer_opacity,
}
