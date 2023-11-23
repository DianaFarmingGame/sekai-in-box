class_name Mono extends MonoLike

@export var define_ref := -1
@export var define_id := &""
@export var override := {}

var define: MonoDefine

func _enter_tree() -> void:
	super._enter_tree()
	if sekai == null:
		push_error("parent isn't Sekai"); return
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

func get_prop(key: Variant) -> Variant:
#	if key is Array:
#		return null # TODO
#	else:
		var ovalue = override.get(key)
		if ovalue != null: return ovalue
		return define.get_prop(key)

func set_prop(key: Variant, value) -> Variant:
	var rawv = define.get_prop(key)
	if rawv != value:
		override[key] = value
	else:
		override.erase(key)
	return value

func get_method(key: StringName) -> Variant:
	return define.get_method(key)

func call_method(key: StringName, argv: Array) -> Variant:
	var vargv := [sekai, self]
	vargv.append_array(argv)
	return define.get_method(key).callv(vargv)
