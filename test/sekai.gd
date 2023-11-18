class_name Sekai extends Node2D

@export_dir var define_dir: String

var defines: Array[MonoDefine]
var defines_by_id := {}
var base_transform: Transform2D
var gss_ctx: Lisper.Context

@export var unit_size := Vector2(16, 16)

func _init(): pass

func _ready():
	base_transform = Transform2D(0, unit_size, 0, Vector2(0, 0))
	queue_redraw()

func _draw():
	pen_clear_transform()
	for child in get_children():
		if child is MonoLike:
			var mono := child as MonoLike
			mono.draw()

func _enter_tree() -> void:
	_init_defines()

func _init_defines() -> void:
	var gsses := []
	var dir := DirAccess.open(define_dir)
	if dir != null:
		dir.list_dir_begin()
		while true:
			var node := dir.get_next()
			if node == "": break
			var file_path := define_dir.path_join(node)
			if not dir.current_is_dir():
				var extd := file_path.split(".")[-2]
				if extd == "gdf":
					var res := ResourceLoader.load(file_path)
					if res is MonoDefine:
						var define := res as MonoDefine
						if define.ref >= defines.size(): defines.resize(define.ref + 1)
						defines[define.ref] = define
				elif extd == "gss":
					gsses.append(file_path)
	
	for d in defines:
		if defines_by_id.has(d.id):
			var pd := defines_by_id[d.id] as MonoDefine
			push_error("duplicated define id: ", pd.name, "(", pd.id, ") and ", d.name, "(", d.id, ")")
		else:
			defines_by_id[d.id] = d
	
	gss_ctx = make_lisper_context()
	gsses.sort()
	for gss_path in gsses:
		var expr := FileAccess.get_file_as_string(gss_path)
		print("[sekai] exec gss: ", gss_path)
		gss_ctx.eval(expr)

func make_lisper_context() -> Lisper.Context:
	var ctx := Lisper.Context.common()
	ctx.macros.merge({
		&"make_define": func (ctx: Lisper.Context, body: Array) -> Variant:
			@warning_ignore("shadowed_variable_base_class")
			var name = body[0][1]
			if name is String or name is StringName:
				var def: MonoDefine
				var pre_def = ctx.get_var(name)
				if pre_def != null:
					def = (pre_def as MonoDefine).fork()
				else:
					print(ClassDB.get_class_list())
					if ClassDB.class_exists(name):
						def = ClassDB.instantiate(name) as MonoDefine
						def.finalize()
					else:
						ctx.log_error(body[0], str("make_define: define class ", name, " not found"))
						return null
				var args = body.slice(1).map(ctx.exec_item)
				for i in args.size() / 2.0:
					var key = args[2 * i]
					var value = args[2 * i + 1]
					match key:
						&"props":
							var props := {}
							for idx in (value.size() / 2):
								props[value[2 * idx]] = value[2 * idx + 1]
							def.do_override_props(props)
				return def
			else:
				ctx.log_error(body[0], str("make_define: ", body[0], " is not a valid token"))
				return null,
	})
	ctx.functions.merge({
		
	})
	return ctx

func call_ref_method(ref: int, method: StringName, argv := []) -> Variant:
	var handle := defines[ref].get_method(method) as Callable
	var rargv := [self]
	rargv.append_array(argv)
	if handle != null:
		return handle.callv(rargv)
	else:
		return null

func get_define_by_id(id: StringName) -> Variant:
	return defines_by_id.get(id)

func pen_draw_texture(texture: Texture2D, rect: Rect2, pmodulate := Color(1, 1, 1, 1)) -> void:
	draw_texture_rect(texture, rect, false, pmodulate)

func pen_draw_texture_region(texture: Texture2D, rect: Rect2, region: Rect2, pmodulate := Color(1, 1, 1, 1)) -> void:
	draw_texture_rect_region(texture, rect, region, pmodulate)

func pen_set_transform(pposition: Vector2, protation := 0.0, pscale := Vector2(1, 1)) -> void:
	draw_set_transform_matrix(base_transform * Transform2D(protation, pscale, 0, pposition))

func pen_clear_transform() -> void:
	draw_set_transform_matrix(base_transform)
