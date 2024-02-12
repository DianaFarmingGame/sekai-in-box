class_name 绘制法_双朝向 extends MonoTrait

var id := &"绘制法_双朝向"
var requires := [&"draw", &"有朝向"]

var props := {
	#--------------------------------------------------------------------------#
	&"draw_flip_h": true,
	&"on_cur_dir": func (ctx: LisperContext, this: Mono, dir: Vector2) -> Vector2:
		if dir.x < -0.01:
			this.setpB(&"draw_flip_h", false)
		if dir.x > 0.01:
			this.setpB(&"draw_flip_h", true)
		return dir,
}
