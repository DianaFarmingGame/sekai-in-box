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

func get_prop(key: StringName) -> Variant:
	var ovalue = override.get(key)
	if ovalue != null: return ovalue
	return define.get_prop(key)

func get_method(key: StringName) -> Variant:
	return define.get_method(key)

func draw() -> void: pass
