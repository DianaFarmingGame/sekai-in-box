class_name UI任务栏 extends MonoTrait

var id := &"UI任务栏"
var requires := [&"ui"]

var props := {
	#
	# 方法
	#
	
	# 打开任务栏
	&"task/toggle": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
		if await this.applymRSU(ctx, &"ui/toggle", [ctrl, &"task"]) != null:
			this.emitmRSUY(ctx, &"control/block")
		else:
			this.emitc(ctx, &"on_task_closed")
			this.emitmRSUY(ctx, &"control/unblock")
		var node = this.applymRSUY(ctx, &"ui/get", [ctrl, &"slots"])
		pass,
	
	#
	# 信号
	#
	
	# 任务栏被关闭时触发
	&"on_task_closed": Prop.Stack(),
	
	#--------------------------------------------------------------------------#
	&"ui_data": {
		&"task": preload("任务栏/task.tscn"),
	},
}
