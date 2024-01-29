class_name Sekai extends Node



#
# 配置项
#

var define_entry: String = ProjectSettings.get_setting("sekai/define_entry")
var gikou_store_dir: String = ProjectSettings.get_setting("sekai/gikou_store_dir")
var render_extra_sight: int = ProjectSettings.get_setting("sekai/render_extra_sight")
var min_inits_per_frame: int = ProjectSettings.get_setting("sekai/min_inits_per_frame")



#
# 全局共享数据
#

var defines: Array[MonoDefine]
var runtime: LisperContext = null
var gikou: Mono = null

# 初始化全局数据
func init_globals() -> void:
	sign_define(Gikou)
	sign_define(Hako)
	runtime = await LisperCommons.make_common_context("sekai")
	await exec_gsx(define_entry)
	_build_caches()



#
# 方法
#

# 全局修改

func exec_gsx(path: String) -> void:
	print_rich("[sekai] ", _line_head_body(), "[color=green][b]exec: ", path, "[/b][/color]")
	_indent += 1
	var stime := Time.get_ticks_usec()
	runtime.print_head = "        " + ('' if _indent == 0 else ''.rpad(_indent - 1, "│ ") + '╎  ')
	await Lisper.exec(runtime, path)
	print_rich("        ", _line_head_end(), "[color=gray]", (Time.get_ticks_usec() - stime) / 1000.0, " ms[/color]")
	runtime.print_head = ""
	_indent -= 1

# 游戏实例/存档相关

func start_gikou(id: String, entry: String) -> void:
	gikou = make_mono(Mono, &"gikou", {id: id})
	await exec_gsx(entry)

func into_gikou(id: String) -> void:
	var file := FileAccess.open(gikou_store_dir.path_join(id + ".gikou"), FileAccess.READ)
	gikou = await Mono.from_data(file.get_var(false))

func record_gikou() -> void:
	DirAccess.make_dir_recursive_absolute(gikou_store_dir)
	var file := FileAccess.open(gikou_store_dir.path_join(gikou.getp(&"id") + ".gikou"), FileAccess.WRITE)
	file.store_var(await Mono.to_data(gikou), false)
	await gikou.restore()

func outof_gikou() -> void:
	await gikou.store()
	gikou = null

# Mono/Define 相关

func sign_define(define: Variant) -> void:
	if not define is MonoDefine: define = define.new()
	define.finalize()
	if define.ref >= defines.size(): defines.resize(define.ref + 1)
	defines[define.ref] = define

func get_define_by_ref(ref: int) -> Variant:
	return defines[ref]

func get_define_by_id(id: StringName) -> Variant:
	return _defines_by_id.get(id)

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

func make_mono_by_define(mono_class: Variant, define: MonoDefine, opts: Dictionary = {}) -> Mono:
	var mono := mono_class.new() as Mono
	mono.define = define
	for k in opts.keys():
		match k:
			&"props":
				mono.cover(&"base", opts[k])
			_:
				mono.set(k, opts[k])
	return mono

func make_mono(mono_class: Variant, ref_id: Variant, opts: Dictionary = {}) -> Variant:
	var define = get_define(ref_id)
	if define == null: return null
	return make_mono_by_define(mono_class, define, opts)

# 资源相关

func get_assert(path: String) -> Variant:
	var res = _assert_cache.get(path)
	if res != null: return res
	res = load(path)
	if res != null:
		_assert_cache[path] = res
		return res
	return null



#
# 初始化
#

func _init() -> void:
	_update_debug_draw()
	Input.use_accumulated_input = false

func _ready() -> void:
	await init_globals()



#------------------------------------------------------------------------------#

#
# 缓存
#

var _defines_by_id := {}
var _assert_cache := {}

func _build_caches() -> void:
	# build _defines_by_id
	for define in defines:
		if define.id != null and define.id != &"":
			if _defines_by_id.has(define.id):
				var pd := _defines_by_id[define.id] as MonoDefine
				push_error("duplicated define id: ", pd.name, "(", pd.id, ") and ", define.name, "(", define.id, ")")
			else:
				_defines_by_id[define.id] = define



#
# 工具函数
#

func _update_debug_draw() -> void:
	ProjectSettings.set_setting(&"sekai/debug_draw",
		ProjectSettings.get_setting(&"sekai/debug_draw_collisible") or \
		ProjectSettings.get_setting(&"sekai/debug_draw_contactable") or \
		ProjectSettings.get_setting(&"sekai/debug_draw_pickable") or \
		ProjectSettings.get_setting(&"sekai/debug_draw_routable") or \
		ProjectSettings.get_setting(&"sekai/debug_draw_solid")
	)

var _indent := 0

func _line_head_body() -> String:
	return '' if _indent == 0 else "[color=gray]" + ''.rpad(_indent - 1, "│ ") + "├╴" + "[/color]"

func _line_head_end() -> String:
	return '' if _indent == 0 else "[color=gray]" + ''.rpad(_indent - 1, "│ ") + "└╴" + "[/color]"
