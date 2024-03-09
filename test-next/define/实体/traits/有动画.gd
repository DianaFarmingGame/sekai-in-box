class_name 有动画 extends MonoTrait

var id := &"有动画"
var requires := [&"draw"]

var props := {
	#
	# 信号
	#
	
	# 当该 Mono 的行为被触发之后被触发
	# @params:
	#		type: StringName,
	#		SekaiControl,
	#		src: Mono: 发起行为的原始对象,
	#		tar: Mono | null: 行为可能指向的目标对象,
	#		InputSet
	&"on_anim_end": Prop.Stack(),
	
	
	
	#
	# 方法
	#
	
	# 设置一个行为
	# @params: type: StringName: 行为的类型, handle: Function: 要设置的行为回调 | null: 删除这个行为
	&"anim/wait": func (ctx: LisperContext, this: Mono, draw: StringName) -> void:
		this.cover(&"anim", {
			&"cur_draw": draw,
			&"draw_timer": 0.0,
		}),
	
	
	
	#--------------------------------------------------------------------------#
}
