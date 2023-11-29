class_name TCollisible extends MonoTrait

var id := &"collisible"

var traits := [TPosition]

var props := {
	&"need_collision": true,
	&"collisible": true,
	&"collision_box": Rect2(-0.5, -0.5, 1, 1),
}

static func draw_debug(sekai: Sekai, this: Mono) -> void:
	if this.getp(&"collisible") and floori(this.position.z) == floori(sekai.control_target.position.z):
		var item := this.get_item() as SekaiItem
		var pos := Vector2(this.position.x, this.position.y)
		var rbox := this.getp(&"collision_box") as Rect2
		var box := Rect2(pos + rbox.position, rbox.size)
		item.draw_rect(box, 0xff000044)
		item.draw_rect(box, 0xff0000ff, false)
