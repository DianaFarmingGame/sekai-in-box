class_name GBlock extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	merge_props(sets, {
		&"asserts": {},
		&"position": Vector2(0, 0),
		&"visible": true,
		&"state": &"normal",
		&"draw_data": {},
		&"cur_drawer": &"normal",
	})
	merge_methods(sets, {
		&"get_assert": func (sekai: Sekai, this, pid: StringName) -> Variant:
			return sekai.get_assert(this.get_prop(&"asserts")[pid]),
		&"draw": func (_sekai: Sekai, this, _dt, t: float) -> void:
			var item := this.get_item() as SekaiItem
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
	})
	return super.do_merge(sets)
