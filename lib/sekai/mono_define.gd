class_name MonoDefine extends TraitLike

@export var ref: int
@export var id: StringName
@export var name: String
@export var traits: Array[TraitLike]
@export var props: Dictionary

func _get_own_traits() -> Array[TraitLike]:
	return traits

func _get_own_props() -> Dictionary:
	return props

func _do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	sets = merge_props(sets, _get_own_props())
	sets = merge_traits(sets, _get_own_traits())
	sets = do_merge(sets)
	return sets

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	return sets
