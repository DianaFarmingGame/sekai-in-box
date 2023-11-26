class_name TRoutable extends MonoTrait

var id := &"routable"

var traits := [TPosition]

var props := {
	&"need_route": true,
	&"routable": true,
	&"route_box": Rect2(-0.5, -0.5, 1, 1),
}

static func draw_debug(sekai: Sekai, this: Mono) -> void:
	if this.get_prop(&"routable") and floori(this.position.z) == floori(sekai.control_target.position.z) - 1:
		var item := this.get_item() as SekaiItem
		var pos := Vector2(this.position.x, this.position.y)
		var rbox := this.get_prop(&"route_box") as Rect2
		var box := Rect2(pos + rbox.position, rbox.size)
		item.draw_rect(box, 0x00ff0044)
		item.draw_rect(box, 0x00ff00ff, false)

