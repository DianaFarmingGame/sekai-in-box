class_name 可控制 extends MonoTrait

var id := &"可控制"
var requires := []

var props := {
	#
	# 配置
	#
	
	# 是否允许接收一般操作 (菜单操作除外)
	&"can_common_action": true,
	
	
	
	#
	# 方法
	#
	
	# 添加一个属性层用于阻塞一般性输入操作
	&"control/block": func (ctx: LisperContext, this: Mono) -> void:
		this.cover(&"control_block", {
			&"can_common_action": false,
			&"can_move": false,
		}),
	
	# 移除一个用于阻塞属性层
	&"control/unblock": func (ctx: LisperContext, this: Mono) -> void:
		this.uncover(&"control_block"),
}
