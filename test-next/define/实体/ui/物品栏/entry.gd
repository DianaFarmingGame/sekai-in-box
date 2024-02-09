extends Control

var this: Mono
var context: LisperContext
var control: SekaiControl

var inited := false

var label: String:
	set(v):
		%Label.text = v
		label = v

var texture: Texture2D:
	set(v):
		%Texture.texture = v
		%TextureShadow.texture = v
		texture = v

var count: int:
	set(v):
		%Count.text = 'x' + str(v)
		count = v

func _ready() -> void:
	if not inited:
		var vtexture = await this.emitmRS(context, &"icon/get_texture")
		if vtexture != null:
			texture = vtexture
		label = this.getp(&"name")
		if this.getp(&"can_stack"):
			count = this.getp(&"stack_count")

const Self := preload("entry.tscn")

func _get_drag_data(at_position: Vector2) -> Variant:
	var node := Self.instantiate()
	node.inited = true
	node.texture = texture
	node.label = label
	node.count = count
	set_drag_preview(node)
	return this
