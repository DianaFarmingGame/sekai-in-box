class_name Sekai extends Node2D

@export_file var define_gss: String
@export_file var entry_gss: String
@export_dir var root_dir: String

var defines: Array[MonoDefine]
var defines_by_id := {}
var gss_ctx: Lisper.Context
var monos := []
var monos_need_route := []
var monos_need_collision := []
var control_target = null

@export var unit_size := Vector3(16, 16, 12)

static var root_vars := {
	&"MonoDefine": MonoDefine.new(),
	&"Entity": GEntity.new(),
	&"Tile": GTile.new(),
	
	&"MonoEntity": MonoEntity,
}

func _init() -> void:
	y_sort_enabled = true

func _ready() -> void:
	_init_sekai()
	Input.use_accumulated_input = false
	get_tree().root.window_input.connect(_on_input)

func _exit_tree() -> void:
#	print("Sekai exit")
	_clear_monos()

func _clear_monos() -> void:
	for mono in monos: mono._outof_sekai()
	monos.clear()
	monos_need_collision.clear()
	monos_need_route.clear()

func _on_input(event: InputEvent) -> void:
	if control_target != null:
		if event is InputEventKey:
			control_target.callm(&"on_input_key", event)

func _init_sekai() -> void:
	defines.clear()
	defines_by_id.clear()
	gss_ctx = make_lisper_context()
	_clear_monos()
	control_target = null
	if define_gss: load_gss(define_gss)
	if entry_gss: load_gss(entry_gss)
	var stime := Time.get_ticks_usec()
	for mono in monos:
		mono._on_init()
	print_rich("[sekai] inited in ", (Time.get_ticks_usec() - stime) / 1000.0, " ms")
	print()

func make_lisper_context() -> Lisper.Context:
	var ctx := Lisper.Context.common()
	
	ctx.def_vars([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], root_vars)
	
	ctx.def_fns([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], Lisper.FnType.GD_RAW_PURE, {
		&"make_define": func (ctx: Lisper.Context, body: Array) -> Variant:
			var def = ctx.exec_node(body[0])
			if def != null:
				def = def.fork()
				var args = ctx.exec_map_part(body.slice(1))
				for k in args.keys():
					match k:
						&"props":
							def.do_override_props(args[k])
						_:
							def.set(k, args[k])
				return def
			else:
				ctx.log_error(body[0], str("make_define: ", body[0], " is not a valid token"))
				return null,
	})
	
	ctx.def_fns([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], Lisper.FnType.GD_RAW, {
		&"sign_define": func (ctx: Lisper.Context, body: Array) -> Variant:
			var def = ctx.exec_node(body[0])
			sign_define(def)
			return def,
		&"make_mono": func (ctx: Lisper.Context, body: Array) -> Mono:
			var mono_class = ctx.exec_node(body[0])
			if mono_class != null:
				var define = get_define(ctx.exec_node(body[1]))
				if define == null: return null
				var mono := mono_class.new() as Mono
				mono.define = define
				var args = ctx.exec_map_part(body.slice(2))
				for k in args.keys():
					match k:
						&"props":
							mono.cover(&"base", args[k])
						_:
							mono.set(k, args[k])
				return mono
			else:
				ctx.log_error(body[0], str("make_mono: ", body[0], " is not a valid token"))
				return null,
		&"mono": func (ctx: Lisper.Context, body: Array) -> Mono:
			var mono = ctx.exec_node(Lisper.Call(&"make_mono", [body]))
			add_mono(mono)
			return mono,
		&"mono_map": func (ctx: Lisper.Context, body: Array) -> MonoMap:
			var map = ctx.exec_node(Lisper.Call(&"make_mono_map", [body]))
			add_mono(map)
			return map,
	})
	
	ctx.def_fns([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], Lisper.FnType.GD_MACRO, {
		&"Define": func (body: Array) -> Array:
			return Lisper.Call(&"defvar", [
				[body[0]],
				[Lisper.Call(&"make_define", [
					body.slice(1),
				])],
			]),
		&"define": func (body: Array) -> Array:
			return Lisper.Call(&"sign_define", [
				[Lisper.Call(&"make_define", [body])],
			]),
		&"import": func (body: Array) -> Array:
			return Lisper.Call(&"defvar", [
				[body[0]],
				[Lisper.Call(&"load", [
					body.slice(1),
				])],
			]),
		&"import_define": func (body: Array) -> Array:
			return Lisper.Call(&"defvar", [
				[body[0]],
				[Lisper.Call(&"load_define", [
					body.slice(1),
				])],
			]),
	})
	
	ctx.def_fns([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], Lisper.FnType.GD_CALL, {
		&"set_control": func (mono: Mono) -> Mono:
			control_target = mono
			return mono,
		&"clear_control": func () -> void:
			control_target = null,
	})
	
	ctx.def_fns([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], Lisper.FnType.GD_CALL_PURE, {
		&"load": func (path: String) -> Resource:
			return get_assert(path),
		&"load_define": func (path: String) -> Resource:
			return get_assert(path).new(),
		&"load_gss": func (path: String) -> void:
			load_gss(root_dir.path_join(path)),
		&"make_mono_map": func (offset: Vector3, cell_size: Vector3, size: Vector2, data := []) -> MonoMap:
			var map := MonoMap.new()
			map.offset = offset
			map.cell_size = cell_size
			map.size = size
			map.data = PackedInt32Array(data)
			return map,
	})
	return ctx

var _indent := 0

func _line_head_body() -> String:
	return '' if _indent == 0 else "[color=gray]" + ''.rpad(_indent - 1, "│ ") + "├╴" + "[/color]"

func _line_head_end() -> String:
	return '' if _indent == 0 else "[color=gray]" + ''.rpad(_indent - 1, "│ ") + "└╴" + "[/color]"

func load_gss(path: String) -> void:
	var expr := FileAccess.get_file_as_string(path)
	print_rich("[sekai] ", _line_head_body(), "[color=green][b]gss: ", path, "[/b][/color]")
	_indent += 1
	var stime := Time.get_ticks_usec()
	gss_ctx.eval(expr)
	print_rich("[sekai] ", _line_head_end(), "[color=gray]", (Time.get_ticks_usec() - stime) / 1000.0, " ms[/color]")
	_indent -= 1

func sign_define(define: MonoDefine) -> void:
	if define.ref >= defines.size(): defines.resize(define.ref + 1)
	defines[define.ref] = define
	if define.id != null and define.id != &"":
		if defines_by_id.has(define.id):
			var pd := defines_by_id[define.id] as MonoDefine
			push_error("duplicated define id: ", pd.name, "(", pd.id, ") and ", define.name, "(", define.id, ")")
		else:
			defines_by_id[define.id] = define

func add_mono(mono) -> void:
	monos.append(mono)
	mono._into_sekai(self)
	if mono.is_need_collision(): monos_need_collision.append(mono)
	if mono.is_need_route(): monos_need_route.append(mono)

func call_ref_method(ref: int, method: StringName, argv := []) -> Variant:
	var handle := defines[ref].get_method(method) as Callable
	var rargv := [self]
	rargv.append_array(argv)
	if handle != null:
		return handle.callv(rargv)
	else:
		return null

func get_define_by_ref(ref: int) -> Variant:
	return defines[ref]

func get_define_by_id(id: StringName) -> Variant:
	return defines_by_id.get(id)

func get_define(ref_id: Variant) -> Variant:
	var define: MonoDefine
	if ref_id is int:
		define = get_define_by_ref(ref_id) as MonoDefine
		if define == null:
			push_error("not found define ref: ", ref_id); return null
	elif ref_id is StringName or ref_id is String:
		define = get_define_by_id(ref_id) as MonoDefine
		if define == null:
			push_error("not found define id: ", ref_id); return null
	else:
		push_error("unable to parse define pointer: ", ref_id); return null
	return define

func get_monos_by_pos(pos: Vector3) -> Array:
	var res := []
	for mono in monos:
		if mono is Mono:
			if (pos - mono.position).abs() < mono.getp(&"size") / 2:
				res.append(mono)
		else:
			res.append_array(mono.get_monos_by_pos(pos))
	return res

var assert_cache := {}

func get_assert(path: String) -> Variant:
	var res = assert_cache.get(path)
	if res != null: return res
	res = load(root_dir.path_join(path))
	if res != null:
		assert_cache[path] = res
		return res
	return null

func make_item() -> SekaiItem:
	var item := SekaiItem.new()
	item.unit_size = unit_size
	return item

func will_route(point: Vector2, z_pos: int) -> Array:
	var result := []
	for mono in monos_need_route:
		mono.will_route(point, z_pos, result)
	return result

func will_collide(region: Rect2, z_pos: int) -> Array:
	var result := []
	for mono in monos_need_collision:
		mono.will_collide(region, z_pos, result)
	return result

func can_pass(region: Rect2, z_pos: int) -> bool:
	return will_collide(region, z_pos).size() == 0 and will_route(region.get_center(), z_pos - 1).size() > 0

func timeout(time: float):
	return get_tree().create_timer(time).timeout

func save_to_path(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	for mono in monos: mono._on_store()
	var vmono := monos.map(func (mono):
		var script = mono.get_script().resource_path
		var data = mono.to_data()
		return [script, data])
	@warning_ignore("incompatible_ternary")
	var save_data := {
		&"define_gss": define_gss,
		&"root_dir": root_dir,
		&"monos": vmono,
		&"control_target": monos.find(control_target) if control_target != null else null,
		&"unit_size": unit_size,
	}
	file.store_var(save_data, false)
	for mono in monos: mono._on_restore()

func load_from_path(path: String) -> void:
	var file := FileAccess.open(path, FileAccess.READ)
	var load_data := file.get_var(false) as Dictionary
	define_gss = load_data[&"define_gss"]
	root_dir = load_data[&"root_dir"]
	unit_size = load_data[&"unit_size"]
	defines.clear()
	defines_by_id.clear()
	gss_ctx = make_lisper_context()
	_clear_monos()
	if define_gss: load_gss(define_gss)
	var vmonos := load_data[&"monos"] as Array
	for entry in vmonos:
		var script = load(entry[0])
		var data = entry[1]
		var mono = script.new()
		mono.from_data(self, data)
		add_mono(mono)
	var target = load_data[&"control_target"]
	control_target = monos[target] if target != null else null
	var stime := Time.get_ticks_usec()
	for mono in monos: mono._on_restore()
	print_rich("[sekai] restore in ", (Time.get_ticks_usec() - stime) / 1000.0, " ms")
	print()
