class_name TDrawStatic extends MonoTrait

var id := &"draw_static"
var requires := [&"drawable", &"draw"]

var props := {
	&"on_draw": Prop.Stack(),
	
	&"on_ready": Prop.puts({
		&"99:draw_static": TDrawStatic.update,
	}),
	&"on_update": Prop.puts({
		&"99:draw_static": TDrawStatic.update,
	}),
}

const TILE_MAP := TDraw.TILE_MAP

static func draw_handle(ctx: LisperContext, this: Mono, draw: Array) -> void:
	match draw[0]:
		&"layers":
			for d in draw[1]:
				draw_handle(ctx, this, d)
			return
		&"diverse":
			draw_handle(ctx, this, draw[1][this.getp(&"cur_draw_variant")])
			return
	var texture = this.getp(&"asserts")[draw[1]]
	var pos := Vector2(this.position.x, this.position.y - this.position.z)
	match draw[0]:
		&"static":
			var clip = draw[2]
			if this.getp(&"draw_flip_h"):
				var trans := Transform2D(0, Vector2(-1, 1), 0, pos + clip[0].position + clip[0].size / 2)
				var rect := Rect2(-clip[0].size / 2, clip[0].size)
				var region := clip[1] as Rect2
				this.puts_on_draw([
					&"0:draw_static", func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, item: SekaiItem) -> void:
						item.pen_set_transform(trans)
						item.pen_draw_texture_region(texture, rect, region)
						item.pen_clear_transform()
				])
			else:
				var rect := Rect2(pos + clip[0].position, clip[0].size)
				var region := clip[1] as Rect2
				this.puts_on_draw([
					&"0:draw_static", func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, item: SekaiItem) -> void:
						item.pen_draw_texture_region(texture, rect, region)
				])
		&"fixed":
			var timeout := draw[2] as float
			var frames := draw[3] as Array
			if this.getp(&"draw_flip_h"):
				this.puts_on_draw([
					&"0:draw_static", func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, item: SekaiItem) -> void:
						var frame_idx := lerpf(0.0, (frames.size() as float), fmod(item.get_time(), timeout) / timeout) as int
						var frame = frames[frame_idx]
						item.pen_set_transform(Transform2D(0, Vector2(-1, 1), 0, pos + frame[0].position + frame[0].size / 2))
						item.pen_draw_texture_region(texture, Rect2(-frame[0].size / 2, frame[0].size), frame[1])
						item.pen_clear_transform()
				])
			else:
				this.puts_on_draw([
					&"0:draw_static", func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, item: SekaiItem) -> void:
						var frame_idx := lerpf(0.0, (frames.size() as float), fmod(item.get_time(), timeout) / timeout) as int
						var frame = frames[frame_idx]
						item.pen_draw_texture_region(texture, Rect2(pos + frame[0].position, frame[0].size), frame[1])
				])
		&"atile":
			var tile := this.getp(&"atile_result") as Array
			if tile.size() == 9:
				var ts := [
					[TILE_MAP[((tile[0] if tile[1] and tile[3] else 0) << 3) + (tile[1] << 2) + (tile[3] << 1) + (1 << 0)], Vector2(0, 0)],
					[TILE_MAP[(tile[1] << 3) + ((tile[2] if tile[1] and tile[5] else 0) << 2) + (1 << 1) + (tile[5] << 0)], Vector2(1, 0)],
					[TILE_MAP[(tile[3] << 3) + (1 << 2) + ((tile[6] if tile[3] and tile[7] else 0) << 1) + (tile[7] << 0)], Vector2(0, 1)],
					[TILE_MAP[(1 << 3) + (tile[5] << 2) + (tile[7] << 1) + ((tile[8] if tile[5] and tile[7] else 0) << 0)], Vector2(1, 1)],
				]
				var list := ts.map(func (t):
					var dbox := draw[2][0] as Rect2
					var cbox := draw[2][1] as Rect2
					dbox.position += dbox.size * t[1] + pos
					cbox.position += cbox.size * t[0]
					return [dbox, cbox]
				)
				this.puts_on_draw([
					&"0:draw_static", func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, item: SekaiItem) -> void:
						for entry in list:
							item.pen_draw_texture_region(texture, entry[0], entry[1])
				])
		_:
			push_error("unknown draw type: ", this.getp(&"draw_type"))

static func update(ctx: LisperContext, this: Mono) -> void:
	for item in this.getp(&"layer").values():
		item.queue_redraw()
	this.prop_on_draw = []
	var cur_draw = this.getp(&"cur_draw")
	if cur_draw == &"": return
	draw_handle(ctx, this, this.getp(&"draw_data")[cur_draw])
