class_name TMoveByInput extends MonoTrait
## 这个 Trait 可以把 TInput 的输入转换为角色的移动行为

var id := &"move_by_input"
var requires := [&"position", &"input", &"process"]

var props := {
	#
	# 配置
	#
	
	# 角色的移动速度 (绝对速度, 对角线上也是这个速度)
	&"move_speed": 3,
	
	# 当前是否可以通过输入进行移动 (不影响程序控制的移动行为)
	&"can_move": true,
	
	
	
	#
	# 信号
	#
	
	# 当移动开始时触发
	# @params: void
	&"on_move_start": Prop.Stack(),
	
	# 当移动结束时触发
	# @params: void
	&"on_move_end": Prop.Stack(),
	
	
	
	#
	# 变量
	#
	
	# 设置以强制在无输入的情况下移动
	&"move_cur_speed": Vector2(0, 0),
	
	
	
	#
	# Setter
	#
	
	# 移动的方向和速度
	# @type: Vector2
	# 单位为 cell/s
	# 设为 Vector(0, 0) 会触发移动停止
	&"on_move_cur_speed": Prop.Stack({
		&"99:move_by_input": func (ctx: LisperContext, this: Mono, speed: Vector2) -> Vector2:
			if speed == Vector2(0, 0):
				await this.emitc(ctx, &"on_move_end")
			else:
				await this.emitc(ctx, &"on_move_start")
			return speed,
	}),
	
	
	
	#--------------------------------------------------------------------------#
	&"on_input": Prop.puts({
		&"0:move_by_input": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, sets: InputSet) -> void:
			if this.getp(&"can_move"):
				var all := sets.triggered
				var dir := Vector2(0, 0)
				if all.has(&"move_up"): dir += Vector2(0, -1)
				if all.has(&"move_down"): dir += Vector2(0, 1)
				if all.has(&"move_left"): dir += Vector2(-1, 0)
				if all.has(&"move_right"): dir += Vector2(1, 0)
				var speed := dir.normalized() * 3
				this.setpW(ctx, &"move_cur_speed", speed)
			pass,
	}),
	&"on_process": Prop.puts({
		&"0:move_by_input": func (ctx: LisperContext, this: Mono, delta: float) -> void:
			var speed := this.getp(&"move_cur_speed") as Vector2
			if speed != Vector2(0, 0):
				var dpos := speed * delta
				await this.callm(ctx, &"position/move", Vector3(dpos.x, 0, 0))
				await this.callm(ctx, &"position/move", Vector3(0, dpos.y, 0)),
	}),
}
