class_name 小阴影 extends MonoTrait

var id := &"小阴影"
var requires := [&"drawable"]

var props := {
	&"asserts": {
		&"小阴影": preload("小阴影.png"),
	},
	&"on_draw": Prop.puts({
		&"-1:小阴影": func (ctx: LisperContext, this: Mono, item: SekaiItem) -> void:
			var pos := Vector2(this.position.x, this.position.y - this.position.z * item.ratio_yz)
			var texture := this.getp(&"asserts")[&"小阴影"] as Texture2D
			var rect := Rect2(-1.5, -1.5, 3, 3)
			rect.position += pos
			item.pen_draw_texture(texture, rect),
	}),
}
