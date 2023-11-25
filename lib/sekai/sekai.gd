class_name Sekai extends Node2D

@export_dir var define_dir: String
@export_dir var assert_dir: String

var defines: Array[MonoDefine]
var defines_by_id := {}
var gss_ctx: Lisper.Context
var monos := []
var monos_need_route := []
var monos_need_collision := []
var control_target = null

@export var unit_size := Vector2(16, 16)

static var root_vars := {
	&"MonoDefine": MonoDefine.new(),
	&"Block": GBlock.new(),
	&"Character": GCharacter.new(),
	
	&"MonoEntity": MonoEntity,
}

func _init() -> void:
	y_sort_enabled = true

func _ready() -> void:
	_init_defines()

func _input(event: InputEvent) -> void:
	if control_target != null:
		if event is InputEventKey:
			control_target.call_method(&"input_key", [event])

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
						sign_define(res)
				elif extd == "gss":
					gsses.append(file_path)
	
	gss_ctx = make_lisper_context()
	gsses.sort()
	for gss_path in gsses:
		var expr := FileAccess.get_file_as_string(gss_path)
		print("[sekai] loading gss: ", gss_path)
		gss_ctx.eval(expr)

func make_lisper_context() -> Lisper.Context:
	var ctx := Lisper.Context.common()
	ctx.vars.merge(root_vars)
	ctx.rawfns.merge({
		&"make_define": func (ctx: Lisper.Context, body: Array) -> Variant:
			var def = ctx.exec_item(body[0])
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
		&"sign_define": func (ctx: Lisper.Context, body: Array) -> Variant:
			var def = ctx.exec_item(body[0])
			sign_define(def)
			return def,
		&"make_mono": func (ctx: Lisper.Context, body: Array) -> Mono:
			var mono_class = ctx.exec_item(body[0])
			if mono_class != null:
				var define = get_define(ctx.exec_item(body[1]))
				if define == null: return null
				var mono = mono_class.new()
				var args = ctx.exec_map_part(body.slice(2))
				for k in args.keys():
					mono.set(k, args[k])
				mono.set_define(define)
				return mono
			else:
				ctx.log_error(body[0], str("make_mono: ", body[0], " is not a valid token"))
				return null,
		&"mono": func (ctx: Lisper.Context, body: Array) -> Mono:
			var mono = ctx.exec_item(Lisper.Call(&"make_mono", [body]))
			add_mono(mono)
			return mono,
		&"mono_map": func (ctx: Lisper.Context, body: Array) -> MonoMap:
			var map = ctx.exec_item(Lisper.Call(&"make_mono_map", [body]))
			add_mono(map)
			return map,
	})
	ctx.macros.merge({
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
	})
	ctx.functions.merge({
		&"make_mono_map": func (offset, size: Vector2, data := []) -> MonoMap:
			var map := MonoMap.new()
			if offset is Vector2:
				map.offset = offset
			else:
				map.offset = Vector2(offset.x, offset.y)
				map.offset_z = offset.z
			map.size = size
			map.data = PackedInt32Array(data)
			return map,
		&"set_control": func (mono: Mono) -> Mono:
			control_target = mono
			return mono,
		&"clear_control": func () -> void:
			control_target = null,
	})
	return ctx

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

var assert_cache := {}

func get_assert(path: String) -> Variant:
	var res = assert_cache.get(path)
	if res != null: return res
	res = load(assert_dir.path_join(path))
	if res != null:
		assert_cache[path] = res
		return res
	return null

func make_item() -> SekaiItem:
	var item := SekaiItem.new()
	item.unit_size = unit_size
	return item

func will_route(point: Vector2, z_pos: int) -> Mono:
	for mono in monos_need_route:
		var res = mono.will_route(point, z_pos)
		if res: return res
	return null

func will_collide(region: Rect2, z_pos: int) -> Mono:
	for mono in monos_need_collision:
		var res = mono.will_collide(region, z_pos)
		if res: return res
	return null

func can_pass(region: Rect2, z_pos: int) -> bool:
	return not will_collide(region, z_pos) and will_route(region.get_center(), z_pos - 1)
