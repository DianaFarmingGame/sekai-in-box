class_name TraitLike extends Resource

const DETECT_DUPLICATE_TRAIT := false

var _props: Dictionary
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
	_props = sets[0]

func _do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	return sets

func do_merge_uid(uid: StringName) -> void:
	if uid != &"":
		if _uids.has(uid):
			if DETECT_DUPLICATE_TRAIT:
				push_warning("duplicated trait, uid: ", uid)
		else:
			_uids.append(uid)

func do_merge_uids(uids: Array[StringName]) -> void:
	for uid in uids: do_merge_uid(uid)

func merge_props(sets: Array[Dictionary], props: Dictionary) -> Array[Dictionary]:
	sets[0] = Prop.do_mergep(sets[0], props)
	return sets

func merge_trait(sets: Array[Dictionary], t) -> Array[Dictionary]:
	if not t is TraitLike: t = t.new()
	t.finalize()
	sets = merge_props(sets, t.get_props())
	do_merge_uids(t.get_uids())
	do_merge_uid(t._get_uid())
	return sets

func merge_traits(sets: Array[Dictionary], traits: Array) -> Array[Dictionary]:
	for t in traits:
		sets = merge_trait(sets, t)
	return sets

func do_override_props(props: Dictionary) -> void:
	_props = Prop.do_mergep(_props, props)

func get_prop(key: StringName, default = null) -> Variant:
	return _props.get(key, default)

func get_props() -> Dictionary:
	return _props

func get_uids() -> Array[StringName]:
	return _uids
