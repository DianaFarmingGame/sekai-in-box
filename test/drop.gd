class_name GDrop extends GEntity

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GDrop"
	ref = 0
	id = "drop"
	merge_traits(sets, [TGroup, TCollisible, TSolid, TProcess, TContainer, TSmallShadow])
	merge_props(sets, {
		&"float_radius": 0.03,
		&"float_cycle_time": 1.2,
		
		&"groups": [&"drop"],
		
		&"on_draw": Prop.puts({
			&"0:drop_item": func (_sekai, this: Mono, sitem: SekaiItem) -> void:
				var pos := Vector2(this.position.x, this.position.y - this.position.z * sitem.ratio_yz)
				var item := this.getp(&"contains")[0] as Mono
				var t := sitem.get_time()
				var hoffset := sin(2 * PI * t / this.getp(&"float_cycle_time")) * this.getp(&"float_radius") as float
				var rect := Rect2(-0.5, -0.8, 1, 1)
				rect.position += pos + Vector2(0, hoffset)
				item.applym(&"icon_draw", [sitem, rect]),
		})
	})
	return sets
