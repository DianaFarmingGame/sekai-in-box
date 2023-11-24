class_name Mono

var define_ref := -1
var define_id: StringName
var override := {}

var sekai: Sekai
var define: MonoDefine

func _into_sekai(psekai: Sekai) -> void:
	sekai = psekai
	if define_ref < 0:
		var d := sekai.get_define_by_id(define_id) as MonoDefine
		if d == null:
			push_error("not found define id: ", define_id); return
		define_ref = d.ref
		define = d
	else:
		define = sekai.get_define(define_ref)
		if define == null:
			push_error("not found define ref: ", define_ref); return
	define.finalize()

func get_prop(key: Variant, default = null) -> Variant:
	var ovalue = override.get(key)
	if ovalue != null: return ovalue
	return define.get_prop(key, default)

func set_prop(key: Variant, value) -> Variant:
	var prev = get_prop(key)
	if prev != value:
		var watcher = define.get_watcher(key)
		if watcher != null: value = watcher.call(sekai, self, prev, value)
	var rawv = define.get_prop(key)
	if rawv != value:
		override[key] = value
	else:
		override.erase(key)
	return value

func get_method(key: StringName) -> Variant:
	return define.get_method(key)

func call_method(key: StringName, argv := []) -> Variant:
	var vargv := [sekai, self]
	vargv.append_array(argv)
	var handle = define.get_method(key)
	if handle != null: return handle.callv(vargv)
	return null

func get_item() -> SekaiItem:
	return SekaiItem.new()
