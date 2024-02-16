class_name UI对话框 extends MonoTrait

var id := &"UI对话框"
var requires := [&"ui"]

var props := {
	#
	# 方法
	#
	
	# 弹出一个对话并等待其结束
	# @params: SekaiControl, {text: String, name?: String, avatar?: Texture2D}
	&"msg_dialog/put": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, param: Dictionary) -> void:
		this.emitmRSUY(ctx, &"control/block")
		await this.applymRSU(ctx, &"ui/oneshot", [ctrl, &"msg_dialog", param])
		this.emitmRSUY(ctx, &"control/unblock"),
	
	
	
	#--------------------------------------------------------------------------#
	&"ui_data": {
		&"msg_dialog": preload("对话框/main.tscn"),
	},
}
