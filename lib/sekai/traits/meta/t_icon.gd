class_name TIcon extends MonoTrait

var id := &"icon"
var requires := [&"assert"]

var props := {
	&"icon": null,
	
	&"icon/draw": func (ctx: LisperContext, this: Mono, item: SekaiItem, rect: Rect2, pmodulate := Color(1, 1, 1, 1)) -> void:
		var icon := this.getp(&"icon") as Array
		var texture = this.getp(&"asserts")[icon[0]]
		var clip = icon[1]
		item.pen_draw_texture_region(texture, rect, clip, pmodulate),
	&"icon/get_texture": func (ctx: LisperContext, this: Mono) -> Texture2D:
		var icon := this.getp(&"icon") as Array
		var texture = this.getp(&"asserts")[icon[0]]
		var clip = icon[1]
		var res := AtlasTexture.new()
		res.atlas = texture
		res.region = clip
		return res,
}
