class_name TDraw extends MonoTrait

var id := &"draw"

var props := {
	&"draw_data": {},
	&"cur_draw": &"",
	&"cur_draw_variant": 0,
	&"draw_timer": 0.0,
	&"flip_h": false,
	
	&"on_draw": Prop.Stack({&"0:draw": TDraw.on_draw}),
	&"draw_reset": func (_sekai, this: Mono) -> void:
		this.setp(&"draw_timer", this.item.get_time()),
	&"draw_to": func (_sekai, this: Mono, draw_id: StringName) -> void:
		this.setp(&"cur_draw", draw_id),
	&"draw_reset_to": func (_sekai, this: Mono, draw_id: StringName) -> void:
		if draw_id != this.getp(&"cur_draw"):
			this.setp(&"cur_draw", draw_id)
			this.setp(&"draw_timer", this.item.get_time()),
	
	&"on_draw_loop": [],
}

static func on_draw(_sekai, this: Mono, item: SekaiItem) -> void:
	var pos := Vector2(this.position.x, this.position.y - this.position.z * item.ratio_yz)
	var cur_draw = this.getp(&"cur_draw")
	if cur_draw == &"": return
	@warning_ignore("shadowed_variable")
	var draw = this.getp(&"draw_data")[cur_draw]
	if draw[0] == &"diverse":
		draw = draw[1][this.getp(&"cur_draw_variant")]
	match draw[0]:
		&"static":
			var texture = this.callm(&"assert_get", draw[1])
			var clip = draw[2]
			if this.getp(&"flip_h"):
				item.pen_set_transform(Transform2D(0, Vector2(-1, 1), 0, pos + clip[0].position + clip[0].size / 2))
				item.pen_draw_texture_region(texture, Rect2(-clip[0].size / 2, clip[0].size), clip[1])
				item.pen_clear_transform()
			else:
				item.pen_draw_texture_region(texture, Rect2(pos + clip[0].position, clip[0].size), clip[1])
		&"fixed":
			var texture = this.callm(&"assert_get", draw[1])
			var timeout := draw[2] as float
			var t := (item.get_time() - this.getp(&"draw_timer")) as float
			if t > timeout and this.emitm(&"on_draw_loop"): return on_draw(_sekai, this, item)
			var frames := draw[3] as Array
			var frame_idx := lerpf(0.0, (frames.size() as float), fmod(t, timeout) / timeout) as int
			var frame = frames[frame_idx]
			if this.getp(&"flip_h"):
				item.pen_set_transform(Transform2D(0, Vector2(-1, 1), 0, pos + frame[0].position + frame[0].size / 2))
				item.pen_draw_texture_region(texture, Rect2(-frame[0].size / 2, frame[0].size), frame[1])
				item.pen_clear_transform()
			else:
				item.pen_draw_texture_region(texture, Rect2(pos + frame[0].position, frame[0].size), frame[1])
		_:
			push_error("unknown draw type: ", this.getp(&"draw_type"))
#	TCollisible.draw_debug(_sekai, this)
#	TRoutable.draw_debug(_sekai, this)
