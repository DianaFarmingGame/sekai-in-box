class_name TSmallShadow extends MonoTrait

var id := &"small_shadow"
var requires := [&"draw"]

var props := {
	&"asserts": {
		&"small_shadow": "assert/阴影.png",
	},
	&"on_draw": Prop.puts({
		&"-1:small_shadow": func (_sekai, this: Mono, item: SekaiItem) -> void:
			var pos := Vector2(this.position.x, this.position.y - this.position.z * item.ratio_yz)
			var texture := await this.callm(&"assert_get", &"small_shadow") as Texture2D
			var rect := Rect2(-1.5, -1.5, 3, 3)
			rect.position += pos
			item.pen_draw_texture(texture, rect),
	}),
}
