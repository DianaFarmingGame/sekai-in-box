class_name MonoDefine extends TraitLike

@export var ref: int
@export var id: StringName
@export var name: String
@export var traits: Array[TraitLike]
@export var props: Dictionary
@export var methods: Dictionary
@export var watchers: Dictionary

func _get_own_traits() -> Array[TraitLike]:
	return traits

func _get_own_props() -> Dictionary:
	return props

func _get_own_methods() -> Dictionary:
	return methods

func _get_own_watchers() -> Dictionary:
	return watchers

func _do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	sets = merge_traits(sets, _get_own_traits())
	sets = merge_props(sets, _get_own_props())
	sets = merge_methods(sets, _get_own_methods())
	sets = merge_watchers(sets, _get_own_watchers())
	sets = do_merge(sets)
	return sets

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	return sets
