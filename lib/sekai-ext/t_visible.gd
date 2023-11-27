class_name TVisible extends MonoTrait

var id := &"visible"

var traits := [TAssert]

var props := {
	&"visible": true,
	&"draw_data": {},
	&"cur_drawer": &"normal",
	&"draw_timer": 0.0,
	&"flip_h": false,
	
	&"draw": TVisible.draw ,
	&"reset_drawer": func (_sekai, this: Mono) -> void:
		this.set_prop(&"draw_timer", this.item.get_time()),
	&"to_drawer": func (_sekai, this: Mono, drawer_id: StringName) -> void:
		this.set_prop(&"cur_drawer", drawer_id),
	&"reset_to_drawer": func (_sekai, this: Mono, drawer_id: StringName) -> void:
		if drawer_id != this.get_prop(&"cur_drawer"):
			this.set_prop(&"cur_drawer", drawer_id)
			this.set_prop(&"draw_timer", this.item.get_time()),
}

static func draw(_sekai, this: Mono) -> void:
	var item := this.item as SekaiItem
	var t := (item.get_time() - this.get_prop(&"draw_timer")) as float
	var pos := Vector2(this.position.x, this.position.y)
	var drawer = this.get_prop(&"draw_data")[this.get_prop(&"cur_drawer")]
	match drawer[0]:
		&"static":
			var texture = this.call_method(&"get_assert", drawer[1])
			if this.get_prop(&"flip_h"):
				item.pen_set_transform(pos + drawer[2].position + drawer[2].size / 2, 0.0, Vector2(-1, 1))
				item.pen_draw_texture_region(texture, Rect2(-drawer[2].size / 2, drawer[2].size), drawer[3])
				item.pen_clear_transform()
			else:
				item.pen_draw_texture_region(texture, Rect2(pos + drawer[2].position, drawer[2].size), drawer[3])
		&"fixed":
			var texture = this.call_method(&"get_assert", drawer[1])
			var timeout := drawer[2] as float
			var frames := drawer[3] as Array
			var frame_idx := lerpf(0.0, (frames.size() as float), fmod(t, timeout) / timeout) as int
			var frame = frames[frame_idx]
			if this.get_prop(&"flip_h"):
				item.pen_set_transform(pos + frame[0].position + frame[0].size / 2, 0.0, Vector2(-1, 1))
				item.pen_draw_texture_region(texture, Rect2(-frame[0].size / 2, frame[0].size), frame[1])
				item.pen_clear_transform()
			else:
				item.pen_draw_texture_region(texture, Rect2(pos + frame[0].position, frame[0].size), frame[1])
		_:
			push_error("unknown draw type: ", this.get_prop(&"draw_type"))
#	TCollisible.draw_debug(_sekai, this)
#	TRoutable.draw_debug(_sekai, this)
