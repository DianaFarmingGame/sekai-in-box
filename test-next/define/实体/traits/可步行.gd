class_name 可步行 extends MonoTrait

var id := &"可步行"
var requires := [&"state", &"move"]

var props := {
	&"state_data": {
		# 当开始移动时启用的状态
		&"walk": {},
	},
	#--------------------------------------------------------------------------#
	&"on_move_start": Prop.puts({
		&"0:可步行": func (ctx: LisperContext, this: Mono) -> void:
			await this.callm(ctx, &"state/to", &"walk"),
	}),
	&"on_move_end": Prop.puts({
		&"0:可步行": func (ctx: LisperContext, this: Mono) -> void:
			await this.callm(ctx, &"state/to", &"idle"),
	}),
}
