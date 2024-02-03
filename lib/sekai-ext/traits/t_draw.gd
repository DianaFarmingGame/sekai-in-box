class_name TDraw extends MonoTrait

var id := &"draw"
var requires := [&"drawable", &"assert", &"position"]

var props := {
	&"draw_data": {},
	&"cur_draw": &"",
	&"cur_draw_variant": 0,
	&"draw_timer": 0.0,
	&"flip_h": false,
	&"on_draw_end": Prop.Stack(), # TODO
	
	&"draw/reset": func (ctx: LisperContext, this: Mono) -> void:
		var item := this.getpB(&"sekai_item") as SekaiItem
		if item != null:
			this.setp(&"draw_timer", item.get_time()),
	&"draw/to": func (ctx: LisperContext, this: Mono, draw_id: StringName) -> void:
		this.setp(&"cur_draw", draw_id),
	&"draw/reset_to": func (ctx: LisperContext, this: Mono, draw_id: StringName) -> void:
		if draw_id != this.getp(&"cur_draw"):
			this.callmRSU(ctx, &"draw/to", draw_id)
			this.emitmRSU(ctx, &"draw/reset"),
	
	&"on_draw": Prop.puts({&"0:draw": TDraw.on_draw}),
	&"on_draw_debug": Prop.Stack(),
}

static func on_draw(ctx: LisperContext, this: Mono, item: SekaiItem) -> void:
	var pos := Vector2(this.position.x, this.position.y - this.position.z * item.ratio_yz)
	var cur_draw = this.getp(&"cur_draw")
	if cur_draw == &"": return
	var draw = this.getp(&"draw_data")[cur_draw]
	if draw[0] == &"diverse":
		draw = draw[1][this.getp(&"cur_draw_variant")]
	match draw[0]:
		&"static":
			var texture = this.getp(&"asserts")[draw[1]]
			var clip = draw[2]
			if this.getp(&"flip_h"):
				item.pen_set_transform(Transform2D(0, Vector2(-1, 1), 0, pos + clip[0].position + clip[0].size / 2))
				item.pen_draw_texture_region(texture, Rect2(-clip[0].size / 2, clip[0].size), clip[1])
				item.pen_clear_transform()
			else:
				item.pen_draw_texture_region(texture, Rect2(pos + clip[0].position, clip[0].size), clip[1])
		&"fixed":
			var texture = this.getp(&"asserts")[draw[1]]
			var timeout := draw[2] as float
			var t := (item.get_time() - this.getp(&"draw_timer")) as float
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
