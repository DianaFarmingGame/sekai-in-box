class_name TCollisible extends MonoTrait

var id := &"collisible"

var traits := [TPosition]

var props := {
	&"need_collision": true,
	&"collisible": true,
	&"collision_box": Rect2(-0.5, -0.5, 1, 1),
}

static func draw_debug(sekai: Sekai, this: Mono) -> void:
	if this.get_prop(&"collisible") and floori(this.get_prop(&"position_z")) == floori(sekai.control_target.get_prop(&"position_z")):
		var item := this.get_item() as SekaiItem
		var pos := this.get_prop(&"position") as Vector2
		var rbox := this.get_prop(&"collision_box") as Rect2
		var box := Rect2(pos + rbox.position, rbox.size)
		item.draw_rect(box, 0xff000044)
		item.draw_rect(box, 0xff0000ff, false)
