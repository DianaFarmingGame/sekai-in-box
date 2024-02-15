class_name 有精力 extends MonoTrait

var id := &"有精力"
var requires := []

var props := {
	#
	# 配置
	#
	
	# Action Point 行动点数/精力值
	&"ap": INF,
	
	
	
	#
	# 方法
	#
	
	# 消耗行动点数
	# @return: true: 成功消耗 | false; 失败
	&"ap/use": func (ctx: LisperContext, this: Mono, count: int) -> bool:
		var ap := this.getpBR(&"ap") as int
		if ap >= count:
			ap -= count
			this.setpW(ctx, &"ap", ap)
			return true
		else:
			return false,
	
	
	
	#
	# 信号
	#
	
	# 当行动点数变化时触发
	&"on_ap_mod": Prop.Stack(),
	
	
	
	#--------------------------------------------------------------------------#
	&"after_ap": Prop.Stack({
		&"0:有精力": func (ctx: LisperContext, this: Mono, ap: int) -> void:
			this.emitc(ctx, &"on_ap_mod"),
	}),
}
