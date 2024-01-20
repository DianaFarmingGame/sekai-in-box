class_name TPickable extends MonoTrait

var id := &"pickable"
var requires := [&"position"]

var props := {
	&"pick_box": Rect2(-0.5, -0.5, 1, 1),
	&"picker_hovered": false,
	
	&"pick_test": func (_sekai, this: Mono, cursor: Vector2) -> Variant:
		var pos := Vector2(this.position.x, this.position.y - this.position.z * this.item.ratio_yz)
		var box := this.getp(&"pick_box") as Rect2
		box.position += pos
		if box.has_point(cursor):
			return (box.get_center() - cursor).length()
		return null,
	
	&"on_picker_in": Prop.Stack({
		&"0:pickable": func (_sekai, this: Mono) -> void:
			await this.setp(&"picker_hovered", true),
	}),
	&"on_picker_out": Prop.Stack({
		&"0:pickable": func (_sekai, this: Mono) -> void:
			await this.setp(&"picker_hovered", false),
	}),
	&"on_draw_debug": Prop.puts({
		&"99:pick_box": TPickable.draw_debug,
	} if ProjectSettings.get_setting(&"sekai/debug_draw_pickable") else {}),
}

static func draw_debug(_sekai, this: Mono, item: SekaiItem) -> void:
	var dcolor := 0x0088ff66 if this.getp(&"picker_hovered") else 0xffffff66
	var pos := Vector2(this.position.x, this.position.y - this.position.z * item.ratio_yz)
	var box := this.getp(&"pick_box") as Rect2
	box.position += pos
	item.draw_rect(box, dcolor)
	item.draw_rect(box, dcolor | 0xff, false)
