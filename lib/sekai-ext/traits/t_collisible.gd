class_name TCollisible extends MonoTrait

var id := &"collisible"
var requires := [&"position", &"group"]

var props := {
	&"need_collision": true,
	&"collisible": true,
	&"collision_boxes": [Rect2(-0.5, -0.5, 1, 1)],
	
	&"collide_test": func (this: Mono, region: Rect2, z_pos: int) -> bool:
		var position := this.position
		if floori(position.z) == z_pos:
			if this.getp(&"collisible"):
				var boxes = this.getp(&"collision_boxes")
				for box in boxes:
					box.position += Vector2(position.x, position.y)
					if box.intersects(region):
						return true
		return false,
	
	&"on_draw_debug": Prop.puts({
		&"99:collision_boxes": TCollisible.draw_debug,
	} if ProjectSettings.get_setting(&"sekai/debug_draw_collisible") else {})
}

static func draw_debug(this: Mono, item: SekaiItem) -> void:
	var tar := sekai.control_target as Mono
	if tar != null:
		if this.getp(&"collisible") and floori(this.position.z) == floori(tar.position.z):
			var pos := Vector2(this.position.x, this.position.y - this.position.z * item.ratio_yz)
			var rboxes = this.getp(&"collision_boxes")
			for rbox in rboxes:
				var box := Rect2(pos + rbox.position, rbox.size)
				item.draw_rect(box, 0xff000044)
				item.draw_rect(box, 0xff0000ff, false)
