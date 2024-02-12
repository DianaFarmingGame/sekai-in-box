extends Control

var this: Mono
var context: LisperContext
var slot: int

var texture: Texture2D:
	set(v):
		%Texture.texture = v
		%TextureShadow.texture = v

var can_modify: bool:
	set(v):
		%DelBtn.visible = %Texture.texture != null and v

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is Mono

func _drop_data(at_position: Vector2, data: Variant) -> void:
	this.applymRSU(context, &"slot/set", [slot, data])

func _on_del_btn_pressed() -> void:
	this.applymRSU(context, &"slot/set", [slot, null])
