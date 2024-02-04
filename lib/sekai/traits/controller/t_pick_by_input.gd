class_name TPickByInput extends MonoTrait
## 这个 Trait 可以把 TInput 的输入转换为拾取事件

var id := &"pick_by_input"
var requires := [&"position", &"input"]

var props := {
	#
	# 配置
	#
	
	# 当前是否可以通过输入进行拾取 (不影响程序控制的拾取行为)
	&"can_pick": true,
	
	
	
	#
	# 信号
	#
	
	# 当输入的 Direction 有可拾取目标时触发
	# @params: Mono: 拾取到的目标 (离光标最近的), InputSet: 透传输入信息
	&"on_pick": Prop.Stack(),
	
	
	
	#--------------------------------------------------------------------------#
	&"on_input": Prop.puts({
		&"0:pick_by_input": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, sets: InputSet) -> void:
			if this.getp(&"can_pick"):
				var dir := sets.direction
				var pos := Vector2(this.position.x, this.position.y - this.position.z * ctrl.unit_size.y / ctrl.unit_size.z) + dir
				var hako := this.get_hako()
				var res := await hako.applymRSU(ctx, &"collect_pick", [ctrl, pos]) as Array
				var min_len := INF
				var min_mono = null
				for pair in res:
					if pair[0] < min_len:
						min_len = pair[0]
						min_mono = pair[1]
				if min_mono != null: this.applyc(ctx, &"on_pick", [min_mono, sets])
			pass,
	}),
}
