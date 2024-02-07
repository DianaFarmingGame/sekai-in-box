class_name SekaiControl extends Control
## 用于渲染 Sekai 的节点，通过设置一个目标对象来渲染其视野内的地图，也可以接收输入来驱动目标对象



#
# 配置项
#

## 默认进入的 Hako ID
@export var hako_id: StringName = &"base"

## 超出渲染裁剪框的额外视野大小
@export var render_extra_sight: int = ProjectSettings.get_setting("sekai/render_extra_sight")

## 每帧至少处理的最低图块加载数量
@export var min_inits_per_frame: int = ProjectSettings.get_setting("sekai/min_inits_per_frame")

## 是否允许在 Sekai 的请求下变更 target TODO
@export var allow_transfer_target: bool = true

## 是否允许主动监听用户输入
@export var allow_input: bool = true

## 是否允许监听 Action 输入
@export var allow_input_action: bool = true

## 是否允许监听 Direction 输入
@export var allow_input_direction: bool = true

## 图块的单位大小
@export var unit_size := Vector3(16, 16, 16):
	set(v):
		if v != unit_size:
			unit_size = v
			unit_size_mod.emit()



#
# 变量
#

## 控制/视图目标
var target: Mono = null:
	set(v):
		if not is_same(target, v):
			if target is Mono:
				await target.callm(context, &"on_target_unset", self)
			target = v
			context.def_const(&"target", target)
			_update_target()

## 执行上下文
var context: LisperContext = null



#
# 方法
#
func set_target(ptarget: Mono) -> void:
	if allow_transfer_target:
		target = ptarget



#
# 信号
#
signal unit_size_mod



#
# 初始化
#

func _init() -> void:
	y_sort_enabled = true
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	context = _make_context()

func _ready() -> void:
	sekai.gikou_changed.connect(_update_gikou)
	sekai.process.connect(_on_process)
	_input_mapper.updated.connect(_on_mapper_input)

func _enter_tree() -> void:
	LisperDebugger.sign_context("SekaiControl", context)

func _exit_tree() -> void:
	LisperDebugger.unsign_context("SekaiControl", context)



#
# 循环
#
func _on_process(delta: float) -> void:
	await _update_sight()
	queue_redraw()
	if _hako != null:
		await _hako.callc(context, &"on_process", delta)

func _draw() -> void:
	_update_draw_caches()



#
# 输入
#

func _gui_input(event: InputEvent) -> void:
	var dir = null
	if event is InputEventMouse:
		var pos := event.position as Vector2
		dir = (pos - size / 2) / Vector2(unit_size.x, unit_size.y)
	if allow_input: _input_mapper.update(event, dir)
	accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if allow_input: _input_mapper.update(event)



# GSM

func gsm(): return ['

defunc (target/set :const :gd ', set_target ,')

']



#------------------------------------------------------------------------------#

#
# 工具函数
#

## 从 Sekai 创建执行上下文
func _make_context() -> LisperContext:
	var ctx := sekai.context.fork() as LisperContext
	ctx.def_const(&"control", self)
	ctx.def_const(&"target", target)
	ctx.def_const(&"hako", _hako)
	return ctx

func _update_gikou() -> void:
	var gikou := sekai.gikou
	if gikou != null:
		target = gikou.getp(&"def_target")
	else:
		target = null

## 每次 target 变更时调用，释放之前的区域，获取新的区域
func _update_target() -> void:
	if target != null:
		_hako = target.get_hako()
		await target.callm(context, &"on_target_set", self)
	else:
		_hako = null
	context.def_const(&"hako", _hako)

## 更新代表视野内 Mono 的数组
func _update_sight() -> void:
	if target != null and _hako != null:
		# 注意 不要复用之前的 _monos_in_sight
		# TODO: 添加视野裁剪
		_monos_in_sight = _hako.getpB(&"contains")
	else:
		_monos_in_sight = []
	await _update_items()

## 触发离开和进入视野 Mono 的事件
func _update_items() -> void:
	var enters := _monos_in_sight.filter(func (m: Mono): return not _prev_monos_in_sight.has(m))
	var exits := _prev_monos_in_sight.filter(func (m: Mono): return not _monos_in_sight.has(m))
	for mono in enters:
		await (mono as Mono).callm(context, &"on_control_enter", self)
	for mono in exits:
		await (mono as Mono).callm(context, &"on_control_exit", self)
	_prev_monos_in_sight = _monos_in_sight

## 更新和 SekaiItem 交互和绘制需要的变量
func _update_draw_caches() -> void:
	_cur_nearest = _next_nearest
	_next_nearest = INF
	_min_count = min_inits_per_frame
	var cpos := Vector3()
	var usize2 := Vector2(unit_size.x, unit_size.y)
	if target is Mono: cpos = target.position
	var pos := Vector2(cpos.x, cpos.y - (cpos.z * unit_size.y) / unit_size.z)
	var offset := -pos + (size * 0.5).floor() / usize2
	var box := Rect2(-offset, size / usize2).grow(render_extra_sight)
	_cam_position = pos
	_item_offset = offset
	_render_box = box
	_frame_time = Time.get_ticks_usec()

## 将输入事件传输至目标对象
func _pass_input(sets: InputSet) -> void:
	if target and target.getp(&"can_input"): await target.applyc(context, &"on_input", [self, sets])


#
# 回调函数
#

func _on_mapper_input(sets: InputSet) -> void:
	if allow_input_action: _pass_input(sets)



#
# 内部变量
#

var _hako: Mono = null
var _input_mapper := InputMapper.new()
var _monos_in_sight := []
var _prev_monos_in_sight := []

var _item_offset := Vector2()
var _cam_position := Vector2()
var _render_box := Rect2()
var _frame_time := 0.0
var _min_count := 0
var _cur_nearest: float = INF
var _next_nearest: float = INF
