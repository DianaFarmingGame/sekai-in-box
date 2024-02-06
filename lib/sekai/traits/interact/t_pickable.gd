class_name TPickable extends MonoTrait
## 为当前 Mono 可拾取性

var id := &"pickable"
var requires := [&"position"]

var props := {
	#
	# 配置
	#
	
	# 当前 Mono 是否会用到拾取特性，性能优化用
	&"need_pick": true,
	
	# 当前是否可拾取
	&"can_pick": true,
	
	# 拾取检测的盒子，默认是一个以 Mono 为中心 1x1 的矩形
	&"pick_box": Rect2(-0.5, -0.5, 1, 1),
	
	
	
	#
	# 方法
	#
	
	# 检测对应位置是否在当前 Mono 拾取范围
	# @params: ctrl: 驱动检测的节点, cursor: 拾取的光标位置 (假设 Z 为 0)
	# @return: null: 当不在范围内时 | float: 当在范围内时，离检测盒中心的距离
	&"collect_pick": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, cursor: Vector2) -> Variant:
		var pos := Vector2(this.position.x, this.position.y - this.position.z * ctrl.unit_size.y / ctrl.unit_size.z)
		var box := this.getp(&"pick_box") as Rect2
		box.position += pos
		if box.has_point(cursor):
			return [[(box.get_center() - cursor).length(), this]]
		return null,
	
	
	
	#--------------------------------------------------------------------------#
	&"on_draw_debug": Prop.puts({
		&"99:pick_box": TPickable.draw_debug,
	} if ProjectSettings.get_setting(&"sekai/debug_draw_pickable") else {}),
}

static func draw_debug(ctx: LisperContext, this: Mono, ctrl: SekaiControl, item: SekaiItem) -> void:
	var dcolor := 0x0088ff66 if this.getp(&"picker_hovered") else 0xffffff66
	var pos := Vector2(this.position.x, this.position.y - this.position.z * item.ratio_yz)
	var box := this.getp(&"pick_box") as Rect2
	box.position += pos
	item.draw_rect(box, dcolor)
	item.draw_rect(box, dcolor | 0xff, false)
