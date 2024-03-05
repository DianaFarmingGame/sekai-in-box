class_name GEntity extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GEntity"
	merge_traits(sets, [TWithLayer ,TPosition, TDrawable, TAssert, TDraw])
	merge_props(sets, {
		&"collect_by_pos": func (ctx: LisperContext, this: Mono, pos: Vector3) -> Mono:
			if (pos - this.position).abs() < this.getp(&"size") / 2:
				return this
			else:
				return null,
		&"collect_by_region": func (ctx: LisperContext, this: Mono, region: AABB) -> Mono:
			if region.has_point(this.position):
				return this
			else:
				return null,
		&"render_box_intersects": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, box: Rect2) -> bool:
			var rbox = this.getp(&"_c_render_box")
			if rbox == null:
				var offset := this.position
				var size := this.getp(&"size") as Vector3
				var ratio_yz := ctrl.unit_size.y / ctrl.unit_size.z
				rbox = Rect2(Vector2(offset.x, offset.y - offset.z * ratio_yz), Vector2()).grow(max(size.x, size.y, size.z) / 2)
				this.setpB(&"_c_render_box", rbox)
			return rbox.intersects(box),
	})
	return sets
