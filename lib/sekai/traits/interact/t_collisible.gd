class_name TCollisible extends MonoTrait
## 为当前 Mono 可碰撞性，和 TSolid 一起使用

var id := &"collisible"
var requires := [&"position", &"group"]

var props := {
	#
	# 配置
	#
	
	# 当前 Mono 是否会用到碰撞特性，性能优化用
	&"need_collision": true,
	
	# 当前是否可碰撞
	&"collisible": true,
	
	# 碰撞检测的盒子 (数组)，默认是一个以 Mono 为中心 1x1 的矩形
	&"collision_boxes": [Rect2(-0.5, -0.5, 1, 1)],
	
	
	
	#
	# 方法
	#
	
	# 检测对应位置是否在当前 Mono 碰撞范围
	# @params: region: 检测的二维矩形, z_pos: 检测的 Z 轴位置
	&"collect_collide": func (ctx: LisperContext, this: Mono, region: Rect2, z_pos: int) -> Mono:
		var position := this.position
		if floori(position.z) == z_pos:
			if this.getp(&"collisible"):
				var boxes = this.getp(&"collision_boxes")
				for box in boxes:
					box.position += Vector2(position.x, position.y)
					if box.intersects(region):
						return this
		return null,
	
	
	
	#--------------------------------------------------------------------------#
	&"on_draw_debug": Prop.puts({
		&"99:collision_boxes": TCollisible.draw_debug,
	} if ProjectSettings.get_setting(&"sekai/debug_draw_collisible") else {})
}

static func draw_debug(ctx: LisperContext, this: Mono, item: SekaiItem) -> void:
	var tar := sekai.control_target as Mono
	if tar != null:
		if this.getp(&"collisible") and floori(this.position.z) == floori(tar.position.z):
			var pos := Vector2(this.position.x, this.position.y - this.position.z * item.ratio_yz)
			var rboxes = this.getp(&"collision_boxes")
			for rbox in rboxes:
				var box := Rect2(pos + rbox.position, rbox.size)
				item.draw_rect(box, 0xff000044)
				item.draw_rect(box, 0xff0000ff, false)
