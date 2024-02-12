class_name GKami extends GEntity

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "创造神"
	ref = 1000
	id = "kami"
	merge_traits(sets, [
		TInput, TProcess, TUI,
		TContactable,
		TMove, TPick,
		TDefTarget,
		可控制,
		UI菜单,
		菜单控制, 主次行为输入,
		神移, 神视, 神变,
	])
	merge_props(sets, {
		&"name": "创造神様",
		&"move_speed": 8,
		&"act_ui": Prop.pushs([&"kami"]),
		&"ui_data": {
			&"kami": preload("ui/main.tscn"),
		},
	})
	return sets

func gsm(): return ['

define/sign(self)

']
