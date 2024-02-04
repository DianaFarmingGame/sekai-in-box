class_name TInput extends MonoTrait
## 为这个 Mono 启用输入接受支持，需要 Mono 被某个 SekaiControl 设为 target 才能接收到输入

var id := &"input"

var props := {
	#
	# 信号
	#
	
	# 当有输入时触发
	# @params: SekaiControl: 触发输入的节点, InputSet: 代表当前输入的对象 (具体信息看对应 Class)
	&"on_input": Prop.Stack(),
}
