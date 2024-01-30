class_name SekaiControl extends Control

## 用于渲染 Sekai 的节点，通过设置一个目标对象来渲染其视野内的地图，也可以接收输入来驱动目标对象



#
# 配置项
#

## 超出渲染裁剪框的额外视野大小
@export var render_extra_sight: int = ProjectSettings.get_setting("sekai/render_extra_sight")

## 每帧至少处理的最低图块加载数量
@export var min_inits_per_frame: int = ProjectSettings.get_setting("sekai/min_inits_per_frame")

## 是否允许在 Sekai 的请求下变更 target
@export var allow_transfer_target: bool = true

## 是否允许主动监听用户输入
@export var allow_input: bool = true

## 是否允许监听 Action 输入
@export var allow_input_action: bool = true

## 是否允许监听 Direction 输入
@export var allow_input_direction: bool = true

## 图块的单位大小
@export var unit_size := Vector3(16, 16, 16)



#
# 变量
#

## 控制/视图目标
var target: Mono = null:
	set(v):
		if not is_same(target, v):
			target = v
			_update_target()

## 执行上下文
@onready
var context: LisperContext = _make_context()



#
# 初始化
#

func _init() -> void:
	y_sort_enabled = true
	_input_mapper.updated.connect(_on_mapper_input)



#
# 输入
#

func _unhandled_input(event: InputEvent) -> void:
	if allow_input: _input_mapper.update(event)



#------------------------------------------------------------------------------#

#
# 工具函数
#

## 从 Sekai 创建执行上下文
func _make_context() -> LisperContext:
	var ctx := sekai.context.fork() as LisperContext
	ctx.def_const(&"*control*", self)
	return ctx

## 每次 target 变更时调用，释放之前的区域，获取新的区域
func _update_target() -> void:
	pass

## 将 Action 的输入事件传输至目标对象
func _pass_action(triggered: Dictionary, pressings: Dictionary, releasings: Dictionary) -> void:
	if target: target.applyv(&"on_input_action", context, [triggered, pressings, releasings])

## 将 Direction 的输入事件传输至目标对象
func _pass_direction(triggered: Dictionary, direction: Vector3) -> void:
	if target: target.applyv(&"on_input_direction", context, [triggered, direction])



#
# 回调函数
#

func _on_mapper_input(triggered: Dictionary, pressings: Dictionary, releasings: Dictionary) -> void:
	if allow_input_action: _pass_action(triggered, pressings, releasings)



#
# 内部变量
#

var _input_mapper := InputMapper.new()