class_name MonoTrait extends TraitLike

# var id := &""
# var traits: Array
# var props: Dictionary
# var requires: Array[StringName]

func _finalize() -> void:
	super._finalize()

func merge(sets: Array[Dictionary], uids: Array, prequires := []) -> Array[Dictionary]:
	var uid := _get_uid()
	if uids.has(uid):
		if TraitLike.DETECT_DUPLICATE_TRAIT:
			push_warning("duplicated trait, uid: ", uid)
		return sets
	for u in _get_requires():
		var missings := []
		if not uids.has(u):
			missings.append(u)
		if missings.size() > 0:
			push_error("Trait ", _get_uid(), ": missing require: ", missings)
			breakpoint
			return sets
	for t in _get_own_traits():
		merge_trait(sets, t, uids, prequires)
	sets = merge_props(sets, _get_own_props())
	uids.append(uid)
	return sets

func _do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	sets = merge_traits(sets, _get_own_traits())
	sets = merge_props(sets, _get_own_props())
	return sets

func _get_own_traits() -> Array:
	var vtraits = get(&"traits")
	if vtraits == null:
		return [] as Array
	else:
		return vtraits

func _get_own_props() -> Dictionary:
	var vprops = get(&"props")
	if vprops == null:
		return {}
	else:
		return vprops

func _get_uid() -> StringName:
	return get_uid()

func _get_requires() -> Array:
	return get_requires()

func get_uid() -> StringName:
	var vid = get(&"id")
	if vid == null:
		return &""
	return vid

func get_requires() -> Array:
	var vrequires = get(&"requires")
	if vrequires == null:
		return []
	else:
		return vrequires
