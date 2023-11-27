class_name TraitLike extends Resource

const DETECT_DUPLICATE_TRAIT := false

var _props: Dictionary
var _watchers: Dictionary
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
	nobj._watchers = _watchers.duplicate(true)
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
	_watchers = sets[1]

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
	sets[0].merge(props)
	return sets

func merge_watchers(sets: Array[Dictionary], watchers: Dictionary) -> Array[Dictionary]:
	sets[1].merge(watchers)
	return sets

func merge_trait(sets: Array[Dictionary], t) -> Array[Dictionary]:
	if not t is TraitLike: t = t.new()
	t.finalize()
	do_merge_uid(t._get_uid())
	sets[0].merge(t.get_props())
	sets[1].merge(t.get_watchers())
	do_merge_uids(t.get_uids())
	return sets

func merge_traits(sets: Array[Dictionary], traits: Array) -> Array[Dictionary]:
	for t in traits:
		sets = merge_trait(sets, t)
	return sets

func do_override_props(props: Dictionary) -> void:
	_props = _merge_prop_entry(_props, props)

func _merge_prop_entry(tar: Variant, src: Variant) -> Variant:
	if tar == null: return src
	if not tar is Dictionary: return src
	for key in src.keys():
		tar[key] = _merge_prop_entry(tar.get(key), src[key])
	return tar

func get_prop(key: StringName, default = null) -> Variant:
	return _props.get(key, default)

func get_props() -> Dictionary:
	return _props

func get_watcher(key: StringName) -> Variant:
	return _watchers.get(key)

func get_watchers() -> Dictionary:
	return _watchers

func get_uids() -> Array[StringName]:
	return _uids
