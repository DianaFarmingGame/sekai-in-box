class_name GHuman extends GAnimal

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "人类"
	merge_traits(sets, [
		有背包, 有快捷栏,
		可控制, 一般控制输入,
	])
	merge_props(sets, {
		&"act_ui": Prop.pushs([&"slots"]),
		&"ui_data": {
			&"slots": preload("ui/快捷栏/main.tscn"),
		}
	})
	return sets
