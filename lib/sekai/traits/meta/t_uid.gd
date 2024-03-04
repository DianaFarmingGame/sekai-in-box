class_name TUID extends MonoTrait

var id := &"uid"

var props := {
	#
	# 配置
	#
	
	# Mono 注册到 Gikou 所使用的 UID，为 null 则不注册
	&"uid": null,
	
	
	
	#--------------------------------------------------------------------------#
	&"on_ready": Prop.puts({
		&"0:uid": func (ctx: LisperContext, this: Mono) -> void:
			var uid = this.getp(&"uid")
			if uid != null:
				sekai.gikou.applymRSUY(ctx, &"set_uid", [uid, this]),
	}),
}
