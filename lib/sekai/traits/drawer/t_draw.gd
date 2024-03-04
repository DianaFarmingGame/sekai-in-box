class_name TDraw extends MonoTrait

var id := &"draw"
var requires := [&"drawable", &"assert", &"position"]

var props := {
	&"draw_data": {},
	&"cur_draw": &"",
	&"cur_draw_variant": 0,
	&"draw_timer": 0.0, # FIXME
	&"draw_flip_h": false,
	&"on_draw_end": Prop.Stack(), # TODO
	
	&"draw/reset": func (ctx: LisperContext, this: Mono) -> void:
		var items := this.getp(&"layer") as Dictionary
		for item in items.values():
			if item != null:
				this.setp(&"draw_timer", item.get_time()),
	&"draw/restick": func (ctx: LisperContext, this: Mono) -> void:
		var cur_draw = this.getp(&"cur_draw")
		if cur_draw == &"": return
		var draw = this.getp(&"draw_data")[cur_draw]
		if draw[0] == &"diverse":
			draw = draw[1][this.getp(&"cur_draw_variant")]
		if draw[0] == &"sticky":
			var timeout := draw[2] as float
			var items := this.getp(&"layer") as Dictionary
			for item in items.values():
				if item != null:
					this.setp(&"draw_timer", item.get_time() + timeout),
	&"draw/to": func (ctx: LisperContext, this: Mono, draw_id: StringName) -> void:
		this.setp(&"cur_draw", draw_id),
	&"draw/reset_to": func (ctx: LisperContext, this: Mono, draw_id: StringName) -> void:
		if draw_id != this.getp(&"cur_draw"):
			this.callmRSU(ctx, &"draw/to", draw_id)
			this.emitmRSU(ctx, &"draw/reset"),
	
	&"on_draw": Prop.puts({&"0:draw": TDraw.on_draw}),
	&"on_draw_debug": Prop.Stack(),
}

const TILE_MAP = [
	Vector2(0, 3), Vector2(1, 3), Vector2(0, 0), Vector2(3, 0),
	Vector2(0, 2), Vector2(1, 0), Vector2(2, 3), Vector2(1, 1),
	Vector2(3, 3), Vector2(0, 1), Vector2(3, 2), Vector2(2, 0),
	Vector2(1, 2), Vector2(2, 2), Vector2(3, 1), Vector2(2, 1),
]

static func on_draw(ctx: LisperContext, this: Mono, ctrl: SekaiControl, item: SekaiItem) -> void:
	var pos := Vector2(this.position.x, this.position.y - this.position.z * item.ratio_yz)
	var cur_draw = this.getp(&"cur_draw")
	if cur_draw == &"": return
	var draw = this.getp(&"draw_data")[cur_draw]
	if draw[0] == &"diverse":
		draw = draw[1][this.getp(&"cur_draw_variant")]
	var texture = this.getp(&"asserts")[draw[1]]
	var frame
	match draw[0]:
		&"static":
			frame = draw[2]
		&"fixed":
			var timeout := draw[2] as float
			var t := item.get_time() - this.getp(&"draw_timer") as float
			var frames := draw[3] as Array
			var frame_idx := frames.size() * fposmod(t / timeout, 1) as int
			frame = frames[frame_idx]
		&"sticky":
			var timeout := draw[2] as float
			var t := item.get_time() - this.getp(&"draw_timer") as float
			var frames := draw[3] as Array
			var frame_idx := clampi(frames.size() * (t / timeout + 1) as int, 0, frames.size() - 1)
			frame = frames[frame_idx]
		&"atile":
			var tile := this.getp(&"atile_result") as Array
			if tile.size() == 9:
				var ts := [
					[TILE_MAP[((tile[0] if tile[1] and tile[3] else 0) << 3) + (tile[1] << 2) + (tile[3] << 1) + (1 << 0)], Vector2(0, 0)],
					[TILE_MAP[(tile[1] << 3) + ((tile[2] if tile[1] and tile[5] else 0) << 2) + (1 << 1) + (tile[5] << 0)], Vector2(1, 0)],
					[TILE_MAP[(tile[3] << 3) + (1 << 2) + ((tile[6] if tile[3] and tile[7] else 0) << 1) + (tile[7] << 0)], Vector2(0, 1)],
					[TILE_MAP[(1 << 3) + (tile[5] << 2) + (tile[7] << 1) + ((tile[8] if tile[5] and tile[7] else 0) << 0)], Vector2(1, 1)],
				]
				for t in ts:
					var dbox := draw[2][0] as Rect2
					var cbox := draw[2][1] as Rect2
					dbox.position += dbox.size * t[1] + pos
					cbox.position += cbox.size * t[0]
					item.pen_draw_texture_region(texture, dbox, cbox)
			return
		_:
			push_error("unknown draw type: ", this.getp(&"draw_type"))
			return
	if this.getp(&"draw_flip_h"):
		item.pen_set_transform(Transform2D(0, Vector2(-1, 1), 0, pos + frame[0].position + frame[0].size / 2))
		item.pen_draw_texture_region(texture, Rect2(-frame[0].size / 2, frame[0].size), frame[1])
		item.pen_clear_transform()
	else:
		item.pen_draw_texture_region(texture, Rect2(pos + frame[0].position, frame[0].size), frame[1])
