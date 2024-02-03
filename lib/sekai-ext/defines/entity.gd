class_name GEntity extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GEntity"
	merge_traits(sets, [TWithItem, TDrawable ,TPosition, TAssert, TDraw])
	merge_props(sets, {
		&"collect_by_pos": func (ctx: LisperContext, this: Mono, pos: Vector3) -> Mono:
			if (pos - this.position).abs() < this.getp(&"size") / 2:
				return this
			else:
				return null,
	})
	return sets
