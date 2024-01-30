class_name TIcon extends MonoTrait

var id := &"icon"
var requires := [&"assert"]

var props := {
	&"icon": null,
	
	&"icon_draw": func (this: Mono, item: SekaiItem, rect: Rect2, pmodulate := Color(1, 1, 1, 1)) -> void:
		var icon := this.getp(&"icon") as Array
		var texture = await this.callm(&"assert_get", icon[0])
		var clip = icon[1]
		item.pen_draw_texture_region(texture, rect, clip, pmodulate),
	&"icon_get_texture": func (this: Mono) -> Texture2D:
		var icon := this.getp(&"icon") as Array
		var texture = await this.callm(&"assert_get", icon[0])
		var clip = icon[1]
		var res := AtlasTexture.new()
		res.atlas = texture
		res.region = clip
		return res,
}
