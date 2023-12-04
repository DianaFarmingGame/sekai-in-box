class_name TDrawStatic extends MonoTrait

var id := &"draw_static"

var props := {
	&"on_draw": null,
	&"on_init": Prop.puts({
		&"99:draw_static": func (_sekai, this: Mono):
			this = this.upgrade()
			var draw = this.getp(&"draw_data")[this.getp(&"cur_draw")]
			match draw[0]:
				&"static":
					var texture = this.callm(&"assert_get", draw[1])
					var clip = draw[2]
					if this.getp(&"flip_h"):
						this.setp(&"on_draw", func (_sekai, this: Mono, item: SekaiItem) -> void:
							var pos := Vector2(this.position.x, this.position.y)
							item.pen_set_transform(pos + clip[0].position + clip[0].size / 2, 0.0, Vector2(-1, 1))
							item.pen_draw_texture_region(texture, Rect2(-clip[0].size / 2, clip[0].size), clip[1])
							item.pen_clear_transform()
							pass)
					else:
						this.setp(&"on_draw", func (_sekai, this: Mono, item: SekaiItem) -> void:
							var pos := Vector2(this.position.x, this.position.y)
							item.pen_draw_texture_region(texture, Rect2(pos + clip[0].position, clip[0].size), clip[1])
							pass)
				&"fixed":
					var texture = this.callm(&"assert_get", draw[1])
					var timeout := draw[2] as float
					var frames := draw[3] as Array
					var timer := this.getp(&"draw_timer") as float
					if this.getp(&"flip_h"):
						this.setp(&"on_draw", func (_sekai, this: Mono, item: SekaiItem) -> void:
							var pos := Vector2(this.position.x, this.position.y)
							var t := (item.get_time() - timer) as float
							var frame_idx := lerpf(0.0, (frames.size() as float), fmod(t, timeout) / timeout) as int
							var frame = frames[frame_idx]
							item.pen_set_transform(pos + frame[0].position + frame[0].size / 2, 0.0, Vector2(-1, 1))
							item.pen_draw_texture_region(texture, Rect2(-frame[0].size / 2, frame[0].size), frame[1])
							item.pen_clear_transform()
							pass)
					else:
						this.setp(&"on_draw", func (_sekai, this: Mono, item: SekaiItem) -> void:
							var pos := Vector2(this.position.x, this.position.y)
							var t := (item.get_time() - timer) as float
							var frame_idx := lerpf(0.0, (frames.size() as float), fmod(t, timeout) / timeout) as int
							var frame = frames[frame_idx]
							item.pen_draw_texture_region(texture, Rect2(pos + frame[0].position, frame[0].size), frame[1])
							pass)
				_:
					push_error("unknown draw type: ", this.getp(&"draw_type"))
			pass,
	}),
}
