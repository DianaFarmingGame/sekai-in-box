class_name 可生长 extends MonoTrait

var id := &"可生长"
var requires := [&"state"]

var props := {
	#
	# 配置
	#
	
	# 当前已经过回数
	&"cur_level_round": 0.0,
	
	# 生长阶段消耗回数
	&"level_cost": [],
	
	
	
	#
	# 变量
	#
	
	# 当前的生长阶段
	&"cur_level": 0,
	
	
	
	#
	# 信号
	#
	
	# 当生长阶段变化时触发
	&"on_level_mod": Prop.Stack(),
	
	
	
	#--------------------------------------------------------------------------#
	&"init_state": &"level:0",
	&"on_round":  Prop.puts({
		&"0:可生长": func (ctx: LisperContext, this: Mono, delta: float) -> void:
			this.setpBW(ctx, &"cur_level_round", this.getp(&"cur_level_round") + delta),
	}),
	&"on_ready": Prop.puts({
		&"99:可生长": 可生长.update_level,
	}),
	&"after_cur_level_round": Prop.Stack({
		&"0:可生长": func (ctx: LisperContext, this: Mono, _round: float) -> void:
			可生长.update_level(ctx, this),
	}),
	&"after_cur_level": Prop.Stack({
		&"0:可生长": func (ctx: LisperContext, this: Mono, level: int) -> void:
			this.emitc(ctx, &"on_level_mod"),
	}),
}

static func update_level(ctx: LisperContext, this: Mono) -> void:
	var pround := this.getp(&"cur_level_round") as float
	var level := this.getp(&"cur_level") as int
	var cost := this.getp(&"level_cost") as Array
	var i = 0
	var cround := 0
	var clevel := 0
	while i < cost.size():
		cround += cost[i]
		if cround > pround:
			clevel = i
			break
		i += 1
		clevel = i
	if clevel != level:
		this.setpBW(ctx, &"cur_level", clevel)
		this.callmRSU(ctx, &"state/to", StringName(str("level:", clevel)))
