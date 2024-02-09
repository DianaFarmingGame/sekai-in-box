class_name TContactable extends MonoTrait

var id := &"contactable"
var requires := [&"position", &"drawable"]

var props := {
	&"contact_rules": {},
	
	&"on_draw_debug": Prop.puts({
		&"99:contact_region": TContactable.draw_debug,
	} if ProjectSettings.get_setting(&"sekai/debug_draw_contactable") else {})
}

static func draw_debug(ctx: LisperContext, this: Mono, ctrl: SekaiControl, item: SekaiItem) -> void:
	var pos := Vector2(this.position.x, this.position.y - this.position.z * item.ratio_yz)
	var rbox := this.getp(&"solid_box") as Rect2
	var box := Rect2(pos + rbox.position, rbox.size)
	item.draw_rect(box, 0x0088ff88)
	item.draw_rect(box, 0x0022ffff, false)
	item.draw_line(Vector2(box.position.x, pos.y), Vector2(box.end.x, pos.y), 0x0022ffff)
	item.draw_line(Vector2(pos.x, box.position.y), Vector2(pos.x, box.end.y), 0x0022ffff)

