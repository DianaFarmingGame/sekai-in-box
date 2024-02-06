class_name TMove extends MonoTrait
## 这个 Trait 可以把 TInput 的输入转换为角色的移动行为

var id := &"move"
var requires := [&"position", &"input", &"process"]

var props := {
	#
	# 配置
	#
	
	# 角色的移动速度 (绝对速度, 对角线上也是这个速度)
	&"move_speed": 3.0,
	
	# 当前是否可以通过输入进行移动 (不影响程序控制的移动行为)
	&"can_move": true,
	
	
	
	#
	# 方法
	#
	
	# 通过偏移量移动
	&"move/by": func (ctx: LisperContext, this: Mono, delta: Vector2) -> bool:
		return await this.applym(ctx, &"move/by_at_speed", [delta, this.getp(&"move_speed")]),
	
	# 通过偏移量移动，同时设定速度
	&"move/by_at_speed": func (ctx: LisperContext, this: Mono, delta: Vector2, move_speed: float) -> bool:
		var target := Vector2(this.position.x, this.position.y) + delta
		return await this.applym(ctx, &"move/to_at_speed", [target, move_speed]),
	
	&"move/to": func (ctx: LisperContext, this: Mono, target: Variant) -> bool:
		return await this.applym(ctx, &"move/to_at_speed", [target, this.getp(&"move_speed")]),
	
	&"move/to_at_speed": func (ctx: LisperContext, this: Mono, target: Variant, max_speed: float) -> bool:
		var can_input = this.getp(&"can_input")
		if can_input: this.setp(&"can_input", false)
		var delta: Vector2
		var blocked := false
		var block_cnt := 0
		var calc_delta: Callable
		if target is Vector2:
			calc_delta = func (): return target - Vector2(this.position.x, this.position.y)
		elif target is Mono:
			calc_delta = func (): return Vector2(target.position.x, target.position.y) - Vector2(this.position.x, this.position.y)
		else:
			ctx.error(str("unknown move target: ", target))
			return false
		delta = calc_delta.call()
		while delta.length() > 0.1:
			var ppos := this.position
			var dt := await sekai.process as float
			var speedv := delta / dt
			var speed := speedv.length()
			if speed > max_speed: speedv *= max_speed / speed
			this.setpBW(ctx, &"move_cur_speed", speedv)
			delta = calc_delta.call()
			if (this.position - ppos).length() < (max_speed * dt) * 0.1:
				block_cnt += 1
				if block_cnt > 5:
					blocked = true
					break
			else:
				block_cnt = 0
		this.setpBW(ctx, &"move_cur_speed", Vector2(0, 0))
		if can_input: this.setp(&"can_input", can_input)
		return not blocked,
	
	
	
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
		&"99:move": func (ctx: LisperContext, this: Mono, speed: Vector2) -> Vector2:
			if speed == Vector2(0, 0):
				await this.emitc(ctx, &"on_move_end")
			else:
				await this.emitc(ctx, &"on_move_start")
			return speed,
	}),
	
	
	
	#--------------------------------------------------------------------------#
	&"on_input": Prop.puts({
		&"0:move": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, sets: InputSet) -> void:
			if this.getp(&"can_move"):
				var all := sets.triggered
				var dir := Vector2(0, 0)
				if all.has(&"move_up"): dir += Vector2(0, -1)
				if all.has(&"move_down"): dir += Vector2(0, 1)
				if all.has(&"move_left"): dir += Vector2(-1, 0)
				if all.has(&"move_right"): dir += Vector2(1, 0)
				var speed := dir.normalized() * 3
				this.setpBW(ctx, &"move_cur_speed", speed)
			pass,
	}),
	&"on_process": Prop.puts({
		&"0:move": func (ctx: LisperContext, this: Mono, delta: float) -> void:
			var speed := this.getpBR(&"move_cur_speed") as Vector2
			if speed != Vector2(0, 0):
				var dpos := speed * delta
				await this.callm(ctx, &"position/move", Vector3(dpos.x, 0, 0))
				await this.callm(ctx, &"position/move", Vector3(0, dpos.y, 0)),
	}),
}
