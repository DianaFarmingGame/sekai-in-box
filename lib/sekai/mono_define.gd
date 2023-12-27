class_name MonoDefine extends TraitLike

@export var ref: int
@export var id: StringName
@export var name: String
@export var traits: Array[TraitLike]
@export var props: Dictionary

func _get_name() -> StringName:
	return str(ref, ":", id, "(", name, ")")

func _get_own_traits() -> Array[TraitLike]:
	return traits

func _get_own_props() -> Dictionary:
	return props

func _do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	sets = do_merge(sets)
	sets = merge_traits(sets, _get_own_traits())
	sets = merge_props(sets, _get_own_props())
	return sets

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	name = "MonoDefine"
	merge_props(sets, {
		&"on_init": [],
		&"on_inited": [],
		&"on_store": [],
		&"on_restore": [],
	})
	return sets
