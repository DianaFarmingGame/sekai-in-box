class_name Sekai extends Node2D

@export_dir var define_dir: String
@export_dir var assert_dir: String

var defines: Array[MonoDefine]
var defines_by_id := {}
var gss_ctx: Lisper.Context
var monos := []
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
		print("[sekai] load gss: ", gss_path)
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
				var mono = mono_class.new()
				var args = ctx.exec_map_part(body.slice(1))
				for k in args.keys():
					mono.set(k, args[k])
				return mono
			else:
				ctx.log_error(body[0], str("make_mono: ", body[0], " is not a valid token"))
				return null,
		&"mono": func (ctx: Lisper.Context, body: Array) -> Mono:
			var mono = ctx.exec_item(Lisper.Call(&"make_mono", [body]))
			add_mono(mono)
			return mono,
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
		&"mono_map": func (offset: Vector2, size: Vector2, data := []) -> MonoMap:
			var map := MonoMap.new()
			map.offset = offset
			map.size = size
			map.data = PackedInt32Array(data)
			add_mono(map)
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

func call_ref_method(ref: int, method: StringName, argv := []) -> Variant:
	var handle := defines[ref].get_method(method) as Callable
	var rargv := [self]
	rargv.append_array(argv)
	if handle != null:
		return handle.callv(rargv)
	else:
		return null

func get_define(ref: int) -> Variant:
	return defines[ref]

func get_define_by_id(id: StringName) -> Variant:
	return defines_by_id.get(id)

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
