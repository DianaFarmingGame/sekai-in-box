class_name 有朝向 extends MonoTrait

var id := &"有朝向"
var requires := [&"move"]

var props := {
	# 一个单位向量，代表角色当前的朝向
	&"cur_dir": Vector2(1, 0),
	
	# 让面部朝向目标
	# @params: Vector2 | Mono: 朝向目标或坐标 (在同一个 Z 轴平面上)
	&"dir/to": func (ctx: LisperContext, this: Mono, target: Variant) -> void:
		var pos: Vector2 = target if target is Vector2 else Vector2(target.position.x, target.position.y)
		var dir := (pos - Vector2(this.position.x, this.position.y)).normalized()
		this.setpBW(ctx, &"cur_dir", dir),
	
	
	
	#--------------------------------------------------------------------------#
	&"on_move_cur_speed": Prop.puts({
		&"0:有朝向": func (ctx: LisperContext, this: Mono, speed: Vector2) -> Vector2:
			if speed.length() > 0:
				this.setpBW(ctx, &"cur_dir", speed.normalized())
			return speed,
	}),
}
