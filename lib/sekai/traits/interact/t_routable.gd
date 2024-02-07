class_name TRoutable extends MonoTrait
## 为当前 Mono 可导航性，和 TSolid 一起使用

var id := &"routable"
var requires := [&"position", &"group"]

var props := {
	#
	# 配置
	#
	
	# 当前 Mono 是否会用到导航特性，性能优化用
	&"need_route": true,
	
	# 当前是否可导航
	&"can_route": true,
	
	# 导航检测的盒子 (数组)，默认是一个以 Mono 为中心 1x1 的矩形
	&"route_boxes": [Rect2(-0.5, -0.5, 1, 1)],
	
	
	
	#
	# 方法
	#
	
	# 检测对应位置是否在当前 Mono 导航范围
	# @params: point: 检测点的二维位置, z_pos: 检测的 Z 轴位置
	&"collect_route": func (ctx: LisperContext, this: Mono, point: Vector2, z_pos: int) -> Mono:
		var position := this.position
		if floori(position.z) == z_pos:
			if this.getp(&"can_route"):
				var boxes = this.getp(&"route_boxes")
				for box in boxes:
					box.position += Vector2(position.x, position.y)
					if box.has_point(point):
						return this
		return null,
	
	
	
	#--------------------------------------------------------------------------#
	&"on_draw_debug": Prop.puts({
		&"99:route_boxes": TRoutable.draw_debug,
	} if ProjectSettings.get_setting(&"sekai/debug_draw_routable") else {})
}

static func draw_debug(ctx: LisperContext, this: Mono, ctrl: SekaiControl, item: SekaiItem) -> void:
	var tar := ctrl.target as Mono
	if tar != null:
		if this.getp(&"can_route") and floori(this.position.z) == floori(tar.position.z + tar.getp(&"solid_route_zoffset")):
			var pos := Vector2(this.position.x, this.position.y - this.position.z * item.ratio_yz + tar.getp(&"solid_route_zoffset") * item.ratio_yz)
			var rboxes = this.getp(&"route_boxes")
			for rbox in rboxes:
				var box := Rect2(pos + rbox.position, rbox.size)
				item.draw_rect(box, 0x00ff0088)
				#item.draw_rect(box, 0x00ff00ff, false)

