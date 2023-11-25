class_name TRoutable extends MonoTrait

var id := &"routable"

var traits := [TPosition]

var props := {
	&"need_route": true,
	&"routable": true,
	&"route_box": Rect2(-0.5, -0.5, 1, 1),
}

static func draw_debug(sekai: Sekai, this: Mono) -> void:
	if this.get_prop(&"routable") and floori(this.get_prop(&"position_z")) == floori(sekai.control_target.get_prop(&"position_z")) - 1:
		var item := this.get_item() as SekaiItem
		var pos := this.get_prop(&"position") as Vector2
		var rbox := this.get_prop(&"route_box") as Rect2
		var box := Rect2(pos + rbox.position, rbox.size)
		item.draw_rect(box, 0x00ff0044)
		item.draw_rect(box, 0x00ff00ff, false)

