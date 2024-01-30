class_name Sekai extends Node
## 全局唯一的 Sekai 管理对象，用于游戏的创建和保存等、Define 的管理、Mono 的创建



#
# 配置项
#

## 全局 Define 生成周期的程序入口
var define_entry: String = ProjectSettings.get_setting("sekai/define_entry")

## Gikou 存档的存储位置
var gikou_store_dir: String = ProjectSettings.get_setting("sekai/gikou_store_dir")



#
# 全局共享数据
#

## 全局 Define 存储
var defines: Array[MonoDefine]

## 当前进入的 Gikou 实例
var gikou: Mono = null

## 全局的执行环境（原则上不应该被 Sekai 以外的对象使用）
@onready
var context: LisperContext = await _make_context()



#
# 方法
#

# 全局修改

## 请求 Sekai 执行全局代码
func exec_gsx(path: String) -> void:
	print_rich("[sekai] ", _line_head_body(), "[color=green][b]exec: ", path, "[/b][/color]")
	_indent += 1
	var stime := Time.get_ticks_usec()
	context.print_head = "        " + ('' if _indent == 0 else ''.rpad(_indent - 1, "│ ") + '╎  ')
	await Lisper.exec(context, path)
	print_rich("        ", _line_head_end(), "[color=gray]", (Time.get_ticks_usec() - stime) / 1000.0, " ms[/color]")
	context.print_head = ""
	_indent -= 1

# 游戏实例/存档相关

## 建立一个新游戏（不会立即存档）
func start_gikou(id: String, entry: String) -> void:
	gikou = make_mono(&"gikou", {id: id})
	await exec_gsx(entry)

## 进入一个已有游戏的存档
func into_gikou(id: String) -> void:
	var file := FileAccess.open(gikou_store_dir.path_join(id + ".gikou"), FileAccess.READ)
	gikou = await Mono.from_data(file.get_var(false))

## 触发当前游戏保存存档
func record_gikou() -> void:
	DirAccess.make_dir_recursive_absolute(gikou_store_dir)
	var file := FileAccess.open(gikou_store_dir.path_join(gikou.getp(&"id") + ".gikou"), FileAccess.WRITE)
	file.store_var(await Mono.to_data(gikou), false)
	await gikou.restore()

## 退出当前游戏
func outof_gikou() -> void:
	await gikou.store()
	gikou = null

# Mono/Define 相关

## 注册一个 Define
func sign_define(define: Variant) -> void:
	if not define is MonoDefine: define = define.new()
	define.finalize()
	if define.ref >= defines.size(): defines.resize(define.ref + 1)
	defines[define.ref] = define

## 创建一个 Mono
func make_mono(ref_id: Variant, opts: Dictionary = {}) -> Variant:
	var define = _get_define(ref_id)
	if define == null: return null
	return _make_mono_by_define(define, opts)

# 资源相关

## 获取一个资源（相当于 load, 但是受控/带缓存的）
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
	await _init_globals()

## 初始化全局数据
func _init_globals() -> void:
	sign_define(Gikou)
	sign_define(Hako)
	if define_entry: await exec_gsx(define_entry)
	_build_caches()



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

func _make_context() -> LisperContext:
	var ctx := await LisperCommons.make_common_context("sekai")
	ctx.def_const(&"sekai", self)
	return ctx

func _get_define(ref_id: Variant) -> Variant:
	var define: MonoDefine
	if ref_id is int:
		define = _get_define_by_ref(ref_id) as MonoDefine
		if define == null:
			push_error("not found define ref: ", ref_id); return null
	elif ref_id is StringName or ref_id is String:
		define = _get_define_by_id(ref_id) as MonoDefine
		if define == null:
			push_error("not found define id: ", ref_id); return null
	else:
		push_error("unable to parse define pointer: ", ref_id); return null
	return define

func _get_define_by_ref(ref: int) -> Variant:
	return defines[ref]

func _get_define_by_id(id: StringName) -> Variant:
	return _defines_by_id.get(id)

func _make_mono_by_define(define: MonoDefine, opts: Dictionary = {}) -> Mono:
	var mono := Mono.new()
	mono.define = define
	for k in opts.keys():
		match k:
			&"props":
				mono.cover(&"base", opts[k])
			_:
				mono.set(k, opts[k])
	return mono

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
