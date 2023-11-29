class_name TDraw extends MonoTrait

var id := &"draw"

var traits := [TAssert]

var props := {
	&"draw_data": {},
	&"cur_draw": &"normal",
	&"draw_timer": 0.0,
	&"flip_h": false,
	
	&"draw": TDraw.draw,
	&"reset_draw": func (_sekai, this: Mono) -> void:
		this.setp(&"draw_timer", this.item.get_time()),
	&"to_draw": func (_sekai, this: Mono, draw_id: StringName) -> void:
		this.setp(&"cur_draw", draw_id),
	&"reset_to_draw": func (_sekai, this: Mono, draw_id: StringName) -> void:
		if draw_id != this.getp(&"cur_draw"):
			this.setp(&"cur_draw", draw_id)
			this.setp(&"draw_timer", this.item.get_time()),
}

static func draw(_sekai, this: Mono, item: SekaiItem) -> void:
	var pos := Vector2(this.position.x, this.position.y)
	@warning_ignore("shadowed_variable")
	var draw = this.getp(&"draw_data")[this.getp(&"cur_draw")]
	match draw[0]:
		&"static":
			var texture = this.callm(&"get_assert", draw[1])
			if this.getp(&"flip_h"):
				item.pen_set_transform(pos + draw[2].position + draw[2].size / 2, 0.0, Vector2(-1, 1))
				item.pen_draw_texture_region(texture, Rect2(-draw[2].size / 2, draw[2].size), draw[3])
				item.pen_clear_transform()
			else:
				item.pen_draw_texture_region(texture, Rect2(pos + draw[2].position, draw[2].size), draw[3])
		&"fixed":
			var texture = this.callm(&"get_assert", draw[1])
			var timeout := draw[2] as float
			var frames := draw[3] as Array
			var t := (item.get_time() - this.getp(&"draw_timer")) as float
			var frame_idx := lerpf(0.0, (frames.size() as float), fmod(t, timeout) / timeout) as int
			var frame = frames[frame_idx]
			if this.getp(&"flip_h"):
				item.pen_set_transform(pos + frame[0].position + frame[0].size / 2, 0.0, Vector2(-1, 1))
				item.pen_draw_texture_region(texture, Rect2(-frame[0].size / 2, frame[0].size), frame[1])
				item.pen_clear_transform()
			else:
				item.pen_draw_texture_region(texture, Rect2(pos + frame[0].position, frame[0].size), frame[1])
		_:
			push_error("unknown draw type: ", this.getp(&"draw_type"))
#	TCollisible.draw_debug(_sekai, this)
#	TRoutable.draw_debug(_sekai, this)
