class_name Sekai extends Node
## 全局唯一的 Sekai 管理对象，用于游戏的创建和保存等、Define 的管理、Mono 的创建



#
# 配置项
#

## 全局 Define 生成周期的程序入口
var define_entry: String = ProjectSettings.get_setting("sekai/define_entry")

## Gikou 存档的存储位置
var gikou_store_dir: String = ProjectSettings.get_setting("sekai/gikou_store_dir")

## 向终端打印时的头部
const print_head: String = "[sekai] "



#
# 信号
#
signal gikou_changed



#
# 全局共享数据
#

## 全局 Define 存储
var defines: Array[MonoDefine]

## 当前进入的 Gikou 实例
var gikou: Mono = null:
	set(v):
		gikou = v
		gikou_changed.emit()

## 全局的执行环境（原则上不应该被 Sekai 以外的对象使用）
var context: LisperContext = null



#
# 方法
#

# 全局修改

## 请求 Sekai 执行全局代码
func exec_gsx(path: String) -> void:
	print_rich(print_head, _line_head_body(), "[b]exec: ", path, "[/b]")
	_indent += 1
	var stime := Time.get_ticks_usec()
	context.print_head = print_head + ('' if _indent == 0 else ''.rpad(_indent - 1, "│ ") + '╎  ')
	await Lisper.exec(context, path)
	print_rich(print_head, _line_head_end(), "[color=gray]", (Time.get_ticks_usec() - stime) / 1000.0, " ms[/color]")
	context.print_head = ""
	_indent -= 1

# 游戏实例/存档相关

## 建立一个新游戏（不会立即存档）
func start_gikou(id: String, entry := "") -> void:
	if gikou != null: await outof_gikou()
	gikou = make_mono(&"gikou", {&"id": id})
	context.push_module_meta({
		&"gikou": gikou,
	})
	if entry != "": await exec_gsx(entry)
	await gikou.init(context)

## 进入一个已有游戏的存档
func into_gikou(id: String) -> void:
	if gikou != null: await outof_gikou()
	var file := FileAccess.open(gikou_store_dir.path_join(id + ".gikou"), FileAccess.READ)
	gikou = Mono.from_data(file.get_var(false))
	context.push_module_meta({
		&"gikou": gikou,
	})
	await gikou.restore(context)

## 触发当前游戏保存存档
func record_gikou() -> void:
	await gikou.store(context)
	DirAccess.make_dir_recursive_absolute(gikou_store_dir)
	var file := FileAccess.open(gikou_store_dir.path_join(gikou.getp(&"id") + ".gikou"), FileAccess.WRITE)
	file.store_var(Mono.to_data(gikou), false)
	await gikou.restore(context)

## 退出当前游戏
func outof_gikou() -> void:
	await gikou.store(context)
	gikou = null
	context.pop_module_meta()

# Mono/Define 相关

## 注册一个 Define
func sign_define(define: Variant) -> void:
	define = MonoDefine.get_define(define)
	define.finalize()
	if define.ref >= defines.size(): defines.resize(define.ref + 1)
	defines[define.ref] = define

## 获取一个 Define
func get_define(ref_id: Variant) -> Variant:
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

## 创建一个 Mono
func make_mono(ref_id: Variant, opts: Dictionary = {}) -> Mono:
	var define = get_define(ref_id)
	if define == null: return null
	return _make_mono_by_define(define, opts)

# 资源相关

## 获取一个资源（相当于 load, 但是受控/带缓存的）
func get_assert(path: String) -> Variant:
	var res = _assert_cache.get(path)
	if res != null: return res
	print_rich(print_head, _line_head_body(), "[color=gray]load: ", path, "[/color]")
	res = load(path)
	if res != null:
		_assert_cache[path] = res
		return res
	return null

## 获取一个游戏期间基本唯一的 index
func get_uidx() -> int:
	_uidx += 1
	return _uidx



#
# 初始化
#

func _init() -> void:
	_update_debug_draw()
	Input.use_accumulated_input = false

func _ready() -> void:
	await _init_context()
	await _init_globals()
	# 封闭执行环境以防止非预测的更改
	context.seal()
	_build_caches()

## 初始化全局数据
func _init_globals() -> void:
	if define_entry: await exec_gsx(define_entry)

## 初始化执行环境
func _init_context() -> void:
	context = await LisperCommons.make_common_context("sekai")
	await Lisper.exec_gsm(context, self)



# GSM

func gsm(): return ['

defunc (sekai/exec :const :gd :apply ',
	func (ctx: LisperContext, args: Array) -> void:
		var mod_dir = ctx.get_var(&"*mod-dir*")
		var path := args[0] as String
		await exec_gsx(Lisper.resolve_path(mod_dir, path))
,')

defunc (gikou/start :const :gd :apply ',
	func (ctx: LisperContext, args: Array) -> void:
		var mod_dir = ctx.get_var(&"*mod-dir*")
		var id := args[0] as String
		var path := args[1] as String
		await start_gikou(id, Lisper.resolve_path(mod_dir, path))
,')

defunc (gikou/into :const :gd ', into_gikou ,')

defunc (gikou/record :const :gd ', record_gikou ,')

defunc (gikou/outof :const :gd ', outof_gikou ,')

defunc (define/sign :const :gd ', sign_define ,')

defunc (mono/make :const :gd ', make_mono ,')

defunc (load :const :gd :apply :pure ',
	func (ctx: LisperContext, args: Array) -> Variant:
		var mod_dir = ctx.get_var(&"*mod-dir*")
		var path := args[0] as String
		return get_assert(Lisper.resolve_path(mod_dir, path))
,')

sekai/exec ("mono/mono.gsm.gd")
sekai/exec ("mono/trait_like.gsm.gd")
sekai/exec ("mono/mono_trait.gsm.gd")
sekai/exec ("mono/mono_define.gsm.gd")
sekai/exec ("mono/prop.gsm.gd")
sekai/exec ("utils/base.gsm.gd")

define/sign (load ("defines/gikou.gd"))
define/sign (load ("defines/hako.gd"))

']



#------------------------------------------------------------------------------#

#
# 缓存
#

var _defines_by_id := {}
var _assert_cache := {}

func _build_caches() -> void:
	# build _defines_by_id
	for define in defines:
		if define != null and define.id != null and define.id != &"":
			if _defines_by_id.has(define.id):
				var pd := _defines_by_id[define.id] as MonoDefine
				push_error("duplicated define id: ", pd.name, "(", pd.id, ") and ", define.name, "(", define.id, ")")
			else:
				_defines_by_id[define.id] = define



#
# 工具函数
#

var _uidx := 0

func _get_define_by_ref(ref: int) -> Variant:
	return defines[ref]

func _get_define_by_id(id: StringName) -> Variant:
	return _defines_by_id.get(id)

func _make_mono_by_define(define: MonoDefine, opts: Dictionary = {}) -> Mono:
	opts = opts.duplicate(true)
	var mono := Mono.new()
	mono.define = define
	mono.cover(&"base", opts)
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