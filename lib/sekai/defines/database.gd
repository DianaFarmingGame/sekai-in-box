class_name Database extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "Database"
	ref = 1
	id = &"db"
	merge_traits(sets, [TDatabase])
	return sets
