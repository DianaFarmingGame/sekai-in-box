class_name Sekai extends Node2D

@export_file var define_gss: String
@export_file var entry_gss: String
@export_dir var root_dir: String

var defines: Array[MonoDefine]
var defines_by_id := {}
var gss_ctx: LisperContext
var monos := []
var monos_need_route := []
var monos_need_collision := []
var control_target = null

@export var unit_size := Vector3(16, 16, 12)

var external_fns := {}

static var root_vars := {
	&"MonoDefine": MonoDefine.new(),
	&"Entity": GEntity.new(),
	&"Tile": GTile.new(),
	
	&"Mono": Mono,
	&"MonoEntity": MonoEntity,
}

func _init() -> void:
	y_sort_enabled = true

signal before_process

@onready var input_mapper := InputMapper.new()

func _ready() -> void:
	_init_sekai()
	Input.use_accumulated_input = false
	var tree := get_tree()
#	tree.root.window_input.connect(_on_input)
	tree.process_frame.connect(func (): before_process.emit())
	input_mapper.updated.connect(_on_input)

func _exit_tree() -> void:
#	print("Sekai exit")
	_clear_monos()

func _clear_monos() -> void:
	for mono in monos: mono._outof_sekai()
	monos.clear()
	monos_need_collision.clear()
	monos_need_route.clear()

signal input_updating(triggered: Dictionary, pressings: Dictionary, releasings: Dictionary)

signal input_updated(triggered: Dictionary, pressings: Dictionary, releasings: Dictionary)

var _block_input := false

func block_input() -> void:
	_block_input = true

func pass_input(triggered: Dictionary, pressings: Dictionary, releasings: Dictionary) -> void:
	if control_target is Mono:
		control_target.applym(&"on_input_action", [triggered, pressings, releasings])
	input_updated.emit(triggered, pressings, releasings)

func _on_input(triggered: Dictionary, pressings: Dictionary, releasings: Dictionary) -> void:
	input_updating.emit(triggered, pressings, releasings)
	if _block_input:
		_block_input = false
		return
	pass_input(triggered, pressings, releasings)

func _unhandled_input(event: InputEvent) -> void:
	input_mapper.update(event)

func _init_sekai() -> void:
	defines.clear()
	defines_by_id.clear()
	gss_ctx = make_lisper_context()
	_clear_monos()
	control_target = null
	if define_gss: exec_gss(define_gss)
	if entry_gss: exec_gss(entry_gss)
	var stime := Time.get_ticks_usec()
	for mono in monos:
		mono._on_init()
	print_rich("[sekai] inited in ", (Time.get_ticks_usec() - stime) / 1000.0, " ms")
	print()

func make_lisper_context() -> LisperContext:
	var ctx := LisperCommons.fork()
	
	ctx.def_vars([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], root_vars)
	
	ctx.def_vars([Lisper.VarFlag.CONST, Lisper.VarFlag.FIX], {
		&"define/make": Lisper.FuncGDRawPure( func (ctx: LisperContext, body: Array) -> Variant:
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
				ctx.log_error(body[0], str("define/make: ", body[0], " is not a valid token"))
				return null),
		&"define/sign": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> Variant:
			var def = ctx.exec_node(body[0])
			sign_define(def)
			return def),
		&"mono/make": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> Mono:
			var mono_class = ctx.exec_node(body[0])
			if mono_class != null:
				var define = get_define(ctx.exec_node(body[1]))
				if define == null: return null
				var mono := mono_class.new() as Mono
				mono.sekai = self
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
				ctx.log_error(body[0], str("mono/make: ", body[0], " is not a valid token"))
				return null),
		&"mono": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> Mono:
			var mono = ctx.exec_node(Lisper.Call(&"mono/make", [body]))
			add_mono(mono)
			return mono),
		&"mono_map": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> MonoMap:
			var map = ctx.exec_node(Lisper.Call(&"mono_map/make", [body]))
			add_mono(map)
			return map),
		&"Define": Lisper.FuncGDMacro( func (body: Array) -> Array:
			return Lisper.Call(&"defvar", [
				[body[0]],
				[Lisper.Call(&"define/make", [
					body.slice(1),
				])],
			])),
		&"define": Lisper.FuncGDMacro( func (body: Array) -> Array:
			return Lisper.Call(&"define/sign", [
				[Lisper.Call(&"define/make", [body])],
			])),
		&"import": Lisper.FuncGDMacro( func (body: Array) -> Array:
			return Lisper.Call(&"defvar", [
				[body[0]],
				[Lisper.Call(&"load", [
					body.slice(1),
				])],
			])),
		&"define/import": Lisper.FuncGDMacro( func (body: Array) -> Array:
			return Lisper.Call(&"defvar", [
				[body[0]],
				[Lisper.Call(&"define/load", [
					body.slice(1),
				])],
			])),
		&"control/set": Lisper.FuncGDCall( func (mono: Mono) -> Mono:
			control_target = mono
			return mono),
		&"control/clear": Lisper.FuncGDCall( func () -> void:
			control_target = null),
		&"load": Lisper.FuncGDCallPure( func (path: String) -> Resource:
			return get_assert(path)),
		&"define/load": Lisper.FuncGDCallPure( func (path: String) -> Resource:
			return get_assert(path).new()),
		&"gss/exec": Lisper.FuncGDCallPure( func (path: String) -> void:
			exec_gss(root_dir.path_join(path))),
		&"mono_map/make": Lisper.FuncGDCallPure( func (offset: Vector3, cell_size: Vector3, size: Vector2, data := []) -> MonoMap:
			var map := MonoMap.new()
			map.sekai = self
			map.offset = offset
			map.cell_size = cell_size
			map.size = size
			map.data = PackedInt32Array(data)
			return map),
		&"csv/load": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> Array:
			var src := ctx.exec_node(body[0]) as String
			var content := FileAccess.get_file_as_string(root_dir.path_join(src))
			return Array(content.split('\n')).map(func (line: String): return line.split(','))),
	})
	return ctx

var _indent := 0

func _line_head_body() -> String:
	return '' if _indent == 0 else "[color=gray]" + ''.rpad(_indent - 1, "│ ") + "├╴" + "[/color]"

func _line_head_end() -> String:
	return '' if _indent == 0 else "[color=gray]" + ''.rpad(_indent - 1, "│ ") + "└╴" + "[/color]"

func exec_gss(path: String) -> void:
	var expr := FileAccess.get_file_as_string(path)
	print_rich("[sekai] ", _line_head_body(), "[color=green][b]gss: ", path, "[/b][/color]")
	_indent += 1
	var stime := Time.get_ticks_usec()
	gss_ctx.eval(expr)
	print_rich("[sekai] ", _line_head_end(), "[color=gray]", (Time.get_ticks_usec() - stime) / 1000.0, " ms[/color]")
	_indent -= 1

func sign_define(define: MonoDefine) -> void:
	define.finalize()
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
	mono._into_sekai()
	if mono.is_need_collision(): monos_need_collision.append(mono)
	if mono.is_need_route(): monos_need_route.append(mono)

func remove_mono(mono) -> void:
	monos_need_collision.erase(mono)
	monos_need_route.erase(mono)
	mono._outof_sekai()
	monos.erase(mono)

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
	if define_gss: exec_gss(define_gss)
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
