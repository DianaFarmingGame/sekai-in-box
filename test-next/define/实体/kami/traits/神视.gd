class_name 神视 extends MonoTrait

var id := &"神视"
var requires := [&"input", &"position", &"draw"]

var props := {
	&"kami_sight_distance": 8,
	&"kami_sight_cursor": Vector3(0, 0, 0),
	
	&"on_draw": Prop.puts({
		&"0:kami_sight": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, item: SekaiItem) -> void:
			if ctrl.is_sub: return
			var dis := this.getp(&"kami_sight_distance") as int
			var cpos := this.position.snapped(Vector3(1, 1, 1))
			var dpos := Vector2(cpos.x, cpos.y - cpos.z * item.ratio_yz)
			var rpos := Vector2(this.position.x, this.position.y - this.position.z * item.ratio_yz)
			for ox in range(-dis, dis + 1):
				for oy in range(-dis, dis + 1):
					var pos := dpos + Vector2(ox, oy)
					var alpha := clampf((float(dis) - (pos - rpos).length()) / dis, 0, 1) * 0.5
					if fmod(pos.x + pos.y, 2) == 0 and alpha > 0:
						item.draw_rect(Rect2(pos - Vector2(0.5, 0.5), Vector2(1, 1)), Color(Color.WHITE, alpha), false)
			var cursor := this.getp(&"kami_sight_cursor") as Vector3
			var scursor := cursor.snapped(Vector3(1, 1, 1))
			var sdcursor := Vector2(scursor.x, scursor.y - scursor.z * item.ratio_yz)
			item.draw_rect(Rect2(sdcursor - Vector2(0.5, 0.5), Vector2(1, 1)), Color(Color.WHITE, 0.4), true)
			#item.draw_rect(Rect2(sdcursor - Vector2(0.5, 0.5), Vector2(1, 1)), Color.BLACK, false)
			pass,
	}),
	&"on_position_mod": Prop.puts({
		&"99:kami_sight": func (ctx: LisperContext, this: Mono) -> void:
			var item := this.getpB(&"layer") as SekaiItem
			var dis := this.getp(&"kami_sight_distance") as int
			item.set_y(this.position.y + dis + 1 + floorf(this.position.z) * 64),
	}),
	&"on_input": Prop.puts({
		&"0:kami_sight": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, sets: InputSet) -> void:
			var cursor := Vector3(sets.direction.x, sets.direction.y, 0) + this.position
			this.setp(&"kami_sight_cursor", cursor),
	}),
}
