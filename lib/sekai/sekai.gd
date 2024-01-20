class_name Sekai extends Control

@export_file var define_gss: String
@export_file var entry_gss: String
@export_dir var root_dir: String
@export var render_border_radius := 4
@export var min_inits_per_frame := 8

var defines: Array[MonoDefine]
var defines_by_id := {}
var gss_ctx: LisperContext
var monos := []
var monos_need_route := []
var monos_need_collision := []
var control_target = null
var control_stack := []
@export var cam_target = Vector2()

@export var unit_size := Vector3(16, 16, 12)

var external_fns := {}

var database_static := {}
var database_runtime := {}

func _init() -> void:
	ProjectSettings.set_setting(&"sekai/debug_draw",
		ProjectSettings.get_setting(&"sekai/debug_draw_collisible") or \
		ProjectSettings.get_setting(&"sekai/debug_draw_contactable") or \
		ProjectSettings.get_setting(&"sekai/debug_draw_pickable") or \
		ProjectSettings.get_setting(&"sekai/debug_draw_routable") or \
		ProjectSettings.get_setting(&"sekai/debug_draw_solid")
	)
	y_sort_enabled = true

signal before_process

@onready var input_mapper := InputMapper.new()

func _ready() -> void:
	_init_sekai()
	Input.use_accumulated_input = false
	var tree := get_tree()
	tree.process_frame.connect(func (): before_process.emit())
	input_mapper.updated.connect(_on_input)

func _process(_delta: float) -> void:
	queue_redraw()

var _item_offset := Vector2()
var _cam_pos := Vector2()
var _render_box := Rect2()
var _frame_time := 0.0
var _min_count := 0
var _cur_nearest: float = INF
var _next_nearest: float = INF

func _draw() -> void:
	_cur_nearest = _next_nearest
	_next_nearest = INF
	_min_count = min_inits_per_frame
	var cpos := Vector3()
	var usize2 := Vector2(unit_size.x, unit_size.y)
	if cam_target is Vector3: cpos = cam_target
	elif cam_target is Mono: cpos = cam_target.position
	var pos := Vector2(cpos.x, cpos.y - (cpos.z * unit_size.y) / unit_size.z)
	var offset := -pos + (Vector2(size) * 0.5).floor() / usize2
	var box := Rect2(-offset, size / usize2).grow(render_border_radius)
	_cam_pos = pos
	_item_offset = offset
	_render_box = box
	_frame_time = Time.get_ticks_usec()

func is_idle(pos: Vector2) -> bool:
	var ne := _cam_pos.distance_squared_to(pos)
	if 1 < (_cur_nearest + 1) / ne:
		_min_count -= 1
		return _min_count >= 0 or Time.get_ticks_usec() - _frame_time < 10_000
	return false

func update_padding_pos(pos: Vector2) -> void:
	var ne := _cam_pos.distance_squared_to(pos)
	if ne < _next_nearest: _next_nearest = ne

func get_item_offset() -> Vector2:
	return _item_offset

func get_render_box() -> Rect2:
	return _render_box

func _exit_tree() -> void:
	_clear_monos()

func _clear_monos() -> void:
	for mono in monos: mono._outof_sekai()
	monos.clear()
	monos_need_collision.clear()
	monos_need_route.clear()

signal input_updating(triggered: Dictionary, pressings: Dictionary, releasings: Dictionary)

signal input_updated(triggered: Dictionary, pressings: Dictionary, releasings: Dictionary)

func cover_control(control = null) -> void:
	control_stack.append(control_target)
	control_target = control

func uncover_control() -> void:
	control_target = control_stack.pop_back()

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

var _inited := false

func _init_sekai() -> void:
	_inited = false
	defines.clear()
	defines_by_id.clear()
	if gss_ctx != null: gss_ctx.destroy()
	gss_ctx = await make_lisper_context()
	_clear_monos()
	control_target = null
	if define_gss: await exec_gsx(define_gss)
	if entry_gss: await exec_gsx(entry_gss)
	var stime := Time.get_ticks_usec()
	for mono in monos: mono._on_init()
	_inited = true
	print_rich("[sekai] inited in ", (Time.get_ticks_usec() - stime) / 1000.0, " ms\n")

	# for i in database_static:
	# 	if i == "行为":
	# 		continue
	# 	print(i, ":", database_static[i])

func make_lisper_context() -> LisperContext:
	var context := await LisperCommons.make_common_context("sekai")
	await Lisper.exec_gsm(context, self)
	return context

var _indent := 0

func _line_head_body() -> String:
	return '' if _indent == 0 else "[color=gray]" + ''.rpad(_indent - 1, "│ ") + "├╴" + "[/color]"

func _line_head_end() -> String:
	return '' if _indent == 0 else "[color=gray]" + ''.rpad(_indent - 1, "│ ") + "└╴" + "[/color]"

func exec_gsx(path: String) -> void:
	print_rich("[sekai] ", _line_head_body(), "[color=green][b]exec: ", path, "[/b][/color]")
	_indent += 1
	var stime := Time.get_ticks_usec()
	gss_ctx.print_head = "        " + ('' if _indent == 0 else ''.rpad(_indent - 1, "│ ") + '╎  ')
	await Lisper.exec(gss_ctx, path)
	print_rich("        ", _line_head_end(), "[color=gray]", (Time.get_ticks_usec() - stime) / 1000.0, " ms[/color]")
	_indent -= 1

func db_define(group: StringName, key: StringName, value, db: Dictionary) -> void:
	db[group] = db[group] if db.has(group) else {}
	db[group][key] = value

func db_get(group: StringName, key: StringName, db: Dictionary) -> Variant:
	if db.has(group) and db[group].has(key):
		return db[group][key]
	else:
		return null

func db_getp(group: StringName, key: StringName, props: StringName, db: Dictionary) -> Variant:
	if db.has(group) and db[group].has(key):
		var data = db[group][key]
		assert(data is Dictionary)
		return data[props] if data.has(props) else null
	else:
		return null

func db_setp(group: StringName, key: StringName, props: StringName, value, db: Dictionary) -> void:
	if db.has(group) and db[group].has(key):
		var data = db[group][key]
		assert(data is Dictionary)
		data[props] = value
	else:
		db[group] = db[group] if db.has(group) else {}
		db[group][key] = {props: value}
	return

func db_pushp(group: StringName, key: StringName, props: StringName, value, db: Dictionary) -> void:
	if db.has(group) and db[group].has(key):
		var data = db[group][key]
		assert(data is Dictionary)
		data[props].append(value)
	else:
		db[group] = db[group] if db.has(group) else {}
		db[group][key] = {props: [value]}
	return

func dbs_define(group: StringName, key: StringName, value) -> void:
	db_define(group, key, value, database_static)

func dbs_get(group: StringName, key: StringName) -> Variant:
	return db_get(group, key, database_static)

func dbs_getp(group: StringName, key: StringName, props: StringName) -> Variant:
	return db_getp(group, key, props, database_static)

func dbs_setp(group: StringName, key: StringName, props: StringName, value) -> void:
	db_setp(group, key, props, value, database_static)

func dbs_pushp(group: StringName, key: StringName, props: StringName, value) -> void:
	db_pushp(group, key, props, value, database_static)

func dbr_define(group: StringName, key: StringName, value) -> void:
	db_define(group, key, value, database_runtime)

func dbr_get(group: StringName, key: StringName) -> Variant:
	return db_get(group, key, database_runtime)

func dbr_getp(group: StringName, key: StringName, props: StringName) -> Variant:
	return db_getp(group, key, props, database_runtime)

func dbr_setp(group: StringName, key: StringName, props: StringName, value) -> void:
	db_setp(group, key, props, value, database_runtime)

func dbr_pushp(group: StringName, key: StringName, props: StringName, value) -> void:
	db_pushp(group, key, props, value, database_runtime)

func load_csgv(path: String) -> Array:
	var content := []
	var file := FileAccess.open(path, FileAccess.READ)
	file.get_csv_line()
	var _head := file.get_csv_line()
	while file.get_position() < file.get_length():
		content.append(Array(file.get_csv_line()).map(func (entry: String):
			return (await gss_ctx.eval(entry.replace('“', '"').replace('”', '"')))[0]))
	return content

func load_csv(path: String) -> Array:
	var content := []
	var file := FileAccess.open(path, FileAccess.READ)
	file.get_csv_line()
	var _head := file.get_csv_line()
	while file.get_position() < file.get_length():
		content.append(Array(file.get_csv_line()))
	return content

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
	if _inited: mono._on_init()

func remove_mono(mono) -> void:
	monos_need_collision.erase(mono)
	monos_need_route.erase(mono)
	mono._outof_sekai()
	monos.erase(mono)

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
		await mono.will_route(point, z_pos, result)
	return result

func will_collide(region: Rect2, z_pos: int) -> Array:
	var result := []
	for mono in monos_need_collision:
		await mono.will_collide(region, z_pos, result)
	return result

func can_pass(region: Rect2, z_pos: int) -> bool:
	return (await will_collide(region, z_pos)).size() == 0 and (await will_route(region.get_center(), z_pos - 1)).size() > 0

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
		&"control_target": monos.find(control_target) if control_target is Mono else control_target,
		&"cam_target": monos.find(cam_target) if cam_target is Mono else cam_target,
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
	if gss_ctx != null: gss_ctx.destroy()
	gss_ctx = await make_lisper_context()
	_clear_monos()
	_inited = false
	if define_gss: await exec_gsx(define_gss)
	var vmonos := load_data[&"monos"] as Array
	for entry in vmonos:
		var script = load(entry[0])
		var data = entry[1]
		var mono = script.new()
		mono.from_data(self, data)
		add_mono(mono)
	var vcontrol_target = load_data[&"control_target"]
	control_target = monos[vcontrol_target] if vcontrol_target is int else vcontrol_target
	var vcam_target = load_data[&"cam_target"]
	cam_target = monos[vcam_target] if vcam_target is int else vcam_target
	var stime := Time.get_ticks_usec()
	for mono in monos: mono._on_restore()
	_inited = true
	print_rich("[sekai] restore in ", (Time.get_ticks_usec() - stime) / 1000.0, " ms")
	print()

func task_on(task_id: StringName):
	var task = dbs_get("任务", task_id)
	assert(task != null, "任务不存在")
	assert(!task.isOpen, "任务已开启")
	task.isOpen = true

func task_off(task_id: StringName):
	var task = dbs_get("任务", task_id)
	assert(task != null, "任务不存在")
	assert(task.isOpen, "任务已关闭")
	task.isOpen = false

func task_desc(task_id: StringName, desc: String):
	var task = dbs_get("任务", task_id)
	assert(task != null, "任务不存在")
	task.desc = desc

func data_set(data_id: StringName, value):
	dbr_define("data", data_id, value)

func data_judge(data: Variant) -> bool:
	var final = dbr2raw(data)
	if final == null: 
		return false

	var res = await gss_ctx.exec(final)
	if res is bool:
		return res
	return false

func dbr2raw(data: Variant) -> Variant:
	var entry = data
	var res := []
	if 	entry[0] == Lisper.TType.ARRAY or \
		entry[0] == Lisper.TType.MAP or	\
		entry[0] == Lisper.TType.LIST:
		for i in range(entry[1].size()):
			var r = dbr2raw(entry[1][i])
			if r == null: 
				return null
			entry[1][i] = r
			
		res = entry
	elif entry[0] == Lisper.TType.TOKEN:
		if gss_ctx.get_var(entry[1]) != null:
			res = entry
			return res
		var key = entry[1]
		var value = dbr_get("data", key)
		assert(value != null, "data not found: " + key)
		
		if value is float:
			res = Lisper.Number(value)
		elif value is bool:
			res = Lisper.Bool(value)
		elif value is String:
			res = Lisper.String(value)
		elif value is Array:
			res = Lisper.List(value)
		
	else:
		res = entry

	return res


func gsm(): return ['

defvar (:const *sekai* ', self ,')

defvar (:const MonoDefine ', MonoDefine.new() ,')
defvar (:const Entity ', GEntity.new() ,')
defvar (:const Tile ', GTile.new() ,')
defvar (:const Mono ', Mono ,')
defvar (:const MonoEntity ', MonoEntity ,')

defunc (delay :const :gd :raw ',
	func (ptimeout: float) -> void:
		await get_tree().create_timer(ptimeout).timeout
,')

defunc (do :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime: return await LisperCommons.compile_keyword_mask_01(ctx, body)
		else:
			var this := await ctx.exec(body[0]) as Mono
			var act_name := await ctx.exec_as_keyword(body[1]) as StringName
			var action = this.getp(&"actions").get(act_name)
			if action == null: action = this.getpR(&"actions").get(act_name) # FIXME
			var argv := [Lisper.Raw(this.sekai), Lisper.Raw(this)]
			argv.append_array(body.slice(2))
			return await ctx.call_fn_raw(action, argv)
,')

defunc (callm :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime: return await LisperCommons.compile_keyword_mask_01(ctx, body)
		else:
			var this := await ctx.exec(body[0]) as Mono
			var method := await ctx.exec_as_keyword(body[1]) as StringName
			var argv := await ctx.execs(body.slice(2)) as Array
			return await this.applym(method, argv)
,')

defunc (getp :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime: return await LisperCommons.compile_keyword_mask_01(ctx, body)
		else:
			var this := await ctx.exec(body[0]) as Mono
			var key := await ctx.exec_as_keyword(body[1]) as StringName
			return this.getp(key)
,')

defunc (setp :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime: return await LisperCommons.compile_keyword_mask_01(ctx, body)
		else:
			var this := await ctx.exec(body[0]) as Mono
			var key := await ctx.exec_as_keyword(body[1]) as StringName
			var value = await ctx.exec(body[2])
			this.setp(key, value)
			return null
,')

defunc (destroy :const :gd ', func (this: Mono): this.destroy() ,')
defunc (queue_destroy :const :gd ', func (this: Mono): this.destroy.call_deferred() ,')

defunc (prop/setp :const :gd :pure ', Prop.setp ,')
defunc (prop/pushs :const :gd :pure ', Prop.pushs ,')
defunc (prop/puts :const :gd :pure ', Prop.puts ,')
defunc (prop/mergep :const :gd :pure ', Prop.mergep ,')

defunc (define/make :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime:
			var cdata := [await ctx.compile(body[0])]
			cdata.append_array(await LisperCommons.compile_map(ctx, body.slice(1)))
			return cdata
		var def = await ctx.exec(body[0])
		if def != null:
			def = def.fork()
			var args = await ctx.exec_map_part(body.slice(1))
			for k in args.keys():
				match k:
					&"props":
						def.do_override_props(args[k])
					_:
						def.set(k, args[k])
			return def
		else:
			await ctx.log_error(body[0], str("define/make: ", body[0], " is not a valid token"))
			return null
,')

defunc (define/sign :const :gd ',
	func (define: MonoDefine) -> MonoDefine:
		sign_define(define)
		return define
,')

defunc (mono/add :const :gd ',
	func (mono: Variant) -> Variant:
		add_mono(mono)
		return mono
,')

defunc (mono/make :const :gd :raw ',
	func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
		if comptime:
			var cdata := await ctx.compiles(body.slice(0, 2))
			cdata.append_array(await LisperCommons.compile_map(ctx, body.slice(2)))
			return cdata
		var mono_class = await ctx.exec(body[0])
		if mono_class != null:
			var define = get_define(await ctx.exec(body[1]))
			if define == null: return null
			var mono := mono_class.new() as Mono
			mono.sekai = self
			mono.define = define
			var args = await ctx.exec_map_part(body.slice(2))
			for k in args.keys():
				match k:
					&"props":
						mono.cover(&"base", args[k])
					_:
						mono.set(k, args[k])
			return mono
		else:
			await ctx.log_error(body[0], str("mono/make: ", body[0], " is not a valid token"))
			return null
,')

defunc (mono :const :gd :macro ',
	func (_ctx, body: Array) -> Array:
		return Lisper.apply(&"mono/add", [
			[Lisper.apply(&"mono/make", [body])],
		])
,')

defunc (mono_map :const :gd :macro ',
	func (_ctx, body: Array) -> Array:
		return Lisper.apply(&"mono/add", [
			[Lisper.apply(&"mono_map/make", [body])],
		])
,')

defunc (Define :const :gd :macro ',
	func (_ctx, body: Array) -> Array:
		return Lisper.apply(&"defvar", [
			[body[0]],
			[Lisper.apply(&"define/make", [
				body.slice(1),
			])],
		])
,')

defunc (define :const :gd :macro ',
	func (_ctx, body: Array) -> Array:
		return Lisper.apply(&"define/sign", [
			[Lisper.apply(&"define/make", [body])],
		])
,')

defunc (import :const :gd :macro ',
	func (_ctx, body: Array) -> Array:
		return Lisper.apply(&"defvar", [[
			body[0],
			Lisper.apply(&"load", [
				body.slice(1),
			]),
		]])
,')

defunc (define/import :const :gd :macro ',
	func (_ctx, body: Array) -> Array:
		return Lisper.apply(&"defvar", [[
			body[0],
			Lisper.apply(&"define/load", [
				body.slice(1),
			]),
		]])
,')

defunc (control/set :const :gd ',
	func (mono: Mono) -> Mono:
		control_target = mono
		return mono
,')

defunc (control/clear :const :gd ',
	func () -> void:
		control_target = null
,')

defunc (cam/set :const :gd ',
	func (mono: Mono) -> Mono:
		cam_target = mono
		return mono
,')

defunc (cam/clear :const :gd ',
	func () -> void:
		cam_target = null
,')

defunc (gsx/exec :const :gd ',
	func (path: String) -> void:
		if path.begins_with('/'):
			await exec_gsx(root_dir.path_join(path.substr(1)))
		else:
			await exec_gsx(path)
,')

defunc (mono_map/make :const :gd ',
	func (offset: Vector3, cell_size: Vector3, psize: Vector2, data := []) -> MonoMap:
		var map := MonoMap.new()
		map.sekai = self
		map.offset = offset
		map.cell_size = cell_size
		map.size = psize
		map.data = PackedInt32Array(data)
		return map
,')

defunc (csgv/map-let :const :gd :macro ',
	func (_ctx, body: Array) -> Array:
		return Lisper.apply(&"array/map-let", [[
			Lisper.apply(&"csgv/load", [[body[0]]]),
		], body.slice(1)])
,')

defunc (csv/map-let :const :gd :macro ',
	func (_ctx, body: Array) -> Array:
		return Lisper.apply(&"array/map-let", [[
			Lisper.apply(&"csv/load", [[body[0]]]),
		], body.slice(1)])
,')

defunc (load :const :gd :pure ',
	func (path: String) -> Resource:
		return get_assert(path)
,')

defunc (define/load :const :gd :pure ',
	func (path: String) -> Resource:
		return get_assert(path).new()
,')

defunc (csgv/load :const :gd :pure ',
	func (path: String) -> Array:
		return load_csgv(root_dir.path_join(path))
,')

defunc (csv/load :const :gd :pure ',
	func (path: String) -> Array:
		return load_csv(root_dir.path_join(path))
,')

defunc (dbs/define :const :gd ',
	func (body: Array) -> void:
		dbs_define(body[0], body[1], body[2])
,')

defunc (dbs/getp :const :gd ',
	func (body: Array) -> Variant:
		return dbs_getp(body[0], body[1], body[2])
,')

defunc (dbs/setp :const :gd ',
	func (body: Array) -> void:
		dbs_setp(body[0], body[1], body[2], body[3])
,')

defunc (dbs/pushp :const :gd ',
	func (body: Array) -> void:
		dbs_pushp(body[0], body[1], body[2], body[3])
,')

defunc (dbs/get :const :gd ',
	func (body: Array) -> Variant:
		return dbs_get(body[0], body[1])
,')

defunc (task/on :const :gd ',
	func (task_id: StringName) -> void:
		task_on(task_id)
		return
,')

defunc (task/off :const :gd ',
	func (task_id: StringName) -> void:
		task_off(task_id)
		return
,')

defunc (task/desc :const :gd ',
	func (task_id: StringName, desc: String) -> void:
		task_desc(task_id, desc)
		return
,')

defunc (data/set :const :gd ',
	func (data_id: StringName, value) -> void:
		data_set(data_id, value)
		return
,')

defunc (dbr/define :const :gd ',
	func (body: Array) -> void:
		dbr_define(body[0], body[1], body[2])
,')

defunc (dbr/getp :const :gd ',
	func (body: Array) -> Variant:
		return dbr_getp(body[0], body[1], body[2])
,')

defunc (dbr/setp :const :gd ',
	func (body: Array) -> void:
		dbr_setp(body[0], body[1], body[2], body[3])
,')

defunc (dbr/pushp :const :gd ',
	func (body: Array) -> void:
		dbr_pushp(body[0], body[1], body[2], body[3])
,')

defunc (dbr/get :const :gd ',
	func (body: Array) -> Variant:
		return dbr_get(body[0], body[1])
,')

defunc (dbr/raw :const :gd ',
	func (data: Variant) -> Variant:
		return dbr2raw(data)
,')

defunc (data/judge :const :gd ',
	func (data: Variant) -> bool:
		return await data_judge(data)
,')

']
