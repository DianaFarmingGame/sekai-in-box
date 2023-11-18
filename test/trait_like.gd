class_name TraitLike extends Resource

var _props: Dictionary
var _methods: Dictionary
var _finalized := false
var _inited := false
var _uids: Array[StringName]

func _init() -> void:
	_inited = true

func _get_uid() -> StringName:
	return &""

func fork() -> TraitLike:
	finalize()
	var nobj := new()
	nobj._props = _props.duplicate(true)
	nobj._methods = _methods.duplicate(true)
	nobj._finalized = true
	return nobj

func finalize() -> void:
	if not _inited:
		push_warning("finalizing before inited, stopped")
		return
	if _finalized: return
	_finalize()

func _finalize() -> void:
	_finalized = true
	_uids = []
	var sets := _do_merge([{}, {}] as Array[Dictionary])
	_props = sets[0]
	_methods = sets[1]

func _do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	return sets

func do_merge_uid(uid: StringName) -> void:
	if uid != &"":
		if _uids.has(uid):
			push_warning("duplicated trait, uid: ", uid)
		else:
			_uids.append(uid)

func do_merge_uids(uids: Array[StringName]) -> void:
	for uid in uids: do_merge_uid(uid)

func merge_props(sets: Array[Dictionary], props: Dictionary) -> Array[Dictionary]:
	sets[0].merge(props)
	return sets

func merge_methods(sets: Array[Dictionary], methods: Dictionary) -> Array[Dictionary]:
	sets[1].merge(methods)
	return sets

func merge_trait(sets: Array[Dictionary], t: TraitLike) -> Array[Dictionary]:
	t.finalize()
	do_merge_uid(t._get_uid())
	sets[0].merge(t.get_props())
	sets[1].merge(t.get_methods())
	do_merge_uids(t.get_uids())
	return sets

func merge_traits(sets: Array[Dictionary], traits: Array[TraitLike]) -> Array[Dictionary]:
	for t in traits:
		sets = merge_trait(sets, t)
	return sets

func do_override_props(props: Dictionary) -> void:
	_props.merge(props, true)

func get_prop(key: StringName) -> Variant:
	return _props.get(key)

func get_props() -> Dictionary:
	return _props

func get_method(key: StringName) -> Variant:
	return _methods.get(key)

func get_methods() -> Dictionary:
	return _methods

func get_uids() -> Array[StringName]:
	return _uids
