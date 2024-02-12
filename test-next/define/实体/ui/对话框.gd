class_name UI对话框 extends MonoTrait

var id := &"UI对话框"
var requires := [&"ui"]

var props := {
	&"dialog/put": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, param: Dictionary) -> void:
		await this.applymRSU(ctx, &"ui/oneshot", [ctrl, &"dialog", param]),
	
	#--------------------------------------------------------------------------#
	&"ui_data": {
		&"dialog": preload("对话框/main.tscn"),
	},
}
