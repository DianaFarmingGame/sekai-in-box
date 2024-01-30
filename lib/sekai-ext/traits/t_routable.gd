class_name TRoutable extends MonoTrait

var id := &"routable"
var requires := [&"position", &"group"]

var props := {
	&"need_route": true,
	&"routable": true,
	&"route_boxes": [Rect2(-0.5, -0.5, 1, 1)],
	
	&"route_test": func (this: Mono, point: Vector2, z_pos: int) -> bool:
		var position := this.position
		if floori(position.z) == z_pos:
			if this.getp(&"routable"):
				var boxes = this.getp(&"route_boxes")
				for box in boxes:
					box.position += Vector2(position.x, position.y)
					if box.has_point(point):
						return true
		return false,
	
	&"on_draw_debug": Prop.puts({
		&"99:route_boxes": TRoutable.draw_debug,
	} if ProjectSettings.get_setting(&"sekai/debug_draw_routable") else {})
}

static func draw_debug(this: Mono, item: SekaiItem) -> void:
	var tar := sekai.control_target as Mono
	if tar != null:
		if this.getp(&"routable") and floori(this.position.z) == floori(tar.position.z + tar.getp(&"solid_route_zoffset")):
			var pos := Vector2(this.position.x, this.position.y - this.position.z * item.ratio_yz + tar.getp(&"solid_route_zoffset") * item.ratio_yz)
			var rboxes = this.getp(&"route_boxes")
			for rbox in rboxes:
				var box := Rect2(pos + rbox.position, rbox.size)
				item.draw_rect(box, 0x00ff0088)
				#item.draw_rect(box, 0x00ff00ff, false)

