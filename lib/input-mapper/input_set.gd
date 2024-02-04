class_name InputSet
## 代表一次输入的信息



#
# 属性
#

## 当前输入的指向 (鼠标，但是被换算为了相对于当前 target 的相对地图偏移，假定在同一个Z轴平面上)
var direction: Vector2

## 当前已经被按下的 Actions
var triggered: Dictionary

## 这次触发被按下的 Actions
var pressings: Dictionary

## 这次触发被释放的 Actions
var releasings: Dictionary



#------------------------------------------------------------------------------#
func _init(pdirection: Vector2, ptriggered: Dictionary, ppressings: Dictionary, preleasings: Dictionary) -> void:
	direction = pdirection
	triggered = ptriggered
	pressings = ppressings
	releasings = preleasings
