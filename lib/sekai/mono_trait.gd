class_name MonoTrait extends TraitLike

# var id := &""
# var traits: Array
# var props: Dictionary

func _finalize() -> void:
#	prepare()
	super._finalize()
#	ready()

func merge(sets: Array[Dictionary], uids: Array[StringName]) -> Array[Dictionary]:
	var uid := _get_uid()
	if uids.has(uid):
		if TraitLike.DETECT_DUPLICATE_TRAIT:
			push_warning("duplicated trait, uid: ", uid)
		return sets
	for t in _get_own_traits():
		merge_trait(sets, t, uids)
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

#func prepare() -> void:
#	pass
#
#func ready() -> void:
#	pass

func get_uid() -> StringName:
	var vid = get(&"id")
	if vid == null:
		return &""
	return vid
