class_name MonoTrait extends TraitLike

# var id := &""
# var traits: Array
# var props: Dictionary
# var methods: Dictionary
# var watchers: Dictionary

func _finalize() -> void:
	prepare()
	super._finalize()
	ready()

func _do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	sets = merge_props(sets, _get_own_props())
	sets = merge_methods(sets, _get_own_methods())
	sets = merge_watchers(sets, _get_own_watchers())
	sets = merge_traits(sets, _get_own_traits())
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

func _get_own_methods() -> Dictionary:
	var vmethods = get(&"methods")
	if vmethods == null:
		return {}
	else:
		return vmethods

func _get_own_watchers() -> Dictionary:
	var vwatchers = get(&"watchers")
	if vwatchers == null:
		return {}
	else:
		return vwatchers

func _get_uid() -> StringName:
	return get_uid()

func prepare() -> void:
	pass

func ready() -> void:
	pass

func get_uid() -> StringName:
	var vid = get(&"id")
	if vid == null:
		return &""
	return vid
