class_name TVisible extends MonoTrait

var id := &"visible"

var traits := [TAssert]

var props := {
	&"visible": true,
	&"draw_data": {},
	&"cur_drawer": &"normal",
	&"draw_timer": 0.0,
}

var methods := {
	&"draw": func (_sekai, this: Mono) -> void:
		var item := this.get_item() as SekaiItem
		var t := (item.get_time() - this.get_prop(&"draw_timer")) as float
		var pos := this.get_prop(&"position") as Vector2
		var drawer = this.get_prop(&"draw_data")[this.get_prop(&"cur_drawer")]
		match drawer[0]:
			&"static":
				var texture = this.call_method(&"get_assert", [drawer[1]])
				item.pen_draw_texture_region(texture, Rect2(pos + drawer[2].position, drawer[2].size), drawer[3])
			&"fixed":
				var texture = this.call_method(&"get_assert", [drawer[1]])
				var timeout := drawer[2] as float
				var frames := drawer[3] as Array
				var frame_idx := lerpf(0.0, (frames.size() as float), fmod(t, timeout) / timeout) as int
				var frame = frames[frame_idx]
				item.pen_draw_texture_region(texture, Rect2(pos + frame[0].position, frame[0].size), frame[1])
			_:
				push_error("unknown draw type: ", this.get_prop(&"draw_type"))
		,
	&"reset_draw_timer": func (_sekai, this: Mono) -> void:
		this.set_prop(&"draw_timer", this.get_item().get_time()),
}
