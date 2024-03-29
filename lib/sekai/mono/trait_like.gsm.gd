class_name TraitLike extends Resource

const DETECT_DUPLICATE_TRAIT := true

var _props: Dictionary
var _finalized := false
var _inited := false
var _uids: Array
var _requires: Array

func _init() -> void:
	_inited = true

func _get_uid() -> StringName:
	return &""

func _get_name() -> StringName:
	return _get_uid()

func _get_requires() -> Array:
	return []

func fork() -> TraitLike:
	finalize()
	var nobj := new()
	nobj._props = _props.duplicate(true)
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
	var sets := _do_merge([{}] as Array[Dictionary])
	var misses := []
	for uid in _requires:
		if not _uids.has(uid):
			misses.append(uid)
	if misses.size() > 0:
		push_error(_get_name(), ": missing require: ", misses)
		breakpoint
		_props = {}
	else:
		_props = sets[0]

func _do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	return sets

func merge_props(sets: Array[Dictionary], props: Dictionary) -> Array[Dictionary]:
	sets[0] = Prop.do_mergep(sets[0], props)
	return sets

func merge_trait(sets: Array[Dictionary], t: Variant, uids: Array, requires := []) -> Array[Dictionary]:
	if not t is MonoTrait: t = t.new()
	sets = t.merge(sets, uids, requires)
	return sets

func merge_traits(sets: Array[Dictionary], traits: Array) -> Array[Dictionary]:
	for t in traits:
		sets = merge_trait(sets, t, _uids, _requires)
	return sets

func do_override_props(props: Dictionary) -> void:
	_props = Prop.do_mergep(_props, props)

func get_prop(key: StringName, default = null) -> Variant:
	return _props.get(key, default)

func get_props() -> Dictionary:
	return _props

func get_uids() -> Array[StringName]:
	return _uids
