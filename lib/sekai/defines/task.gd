class_name Task extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "Task"

	ref = 4
	id = &"task"

	merge_traits(sets, [TProcess, TTask])

	merge_props(sets, {

	})

	return sets
