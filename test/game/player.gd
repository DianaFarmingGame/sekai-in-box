class_name GPlayer extends MonoDefine

var texture := preload("./assert/scifitiles-sheet.png")

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	merge_props(sets, {
		&"position": Vector2(0, 0),
		&"visible": true,
	})
	merge_methods(sets, {
		&"draw": func (sekai: Sekai, this: Mono) -> void:
			var pos := this.get_prop(&"position") as Vector2
			sekai.pen_draw_texture_region(texture, Rect2(pos, Vector2(1, 1)), Rect2(0, 0, 32, 32))
	})
	return super.do_merge(sets)
