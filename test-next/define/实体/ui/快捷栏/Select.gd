extends Control

var this: Mono
var context: LisperContext
var slot: int

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	return data is Mono

func _drop_data(at_position: Vector2, data: Variant) -> void:
	this.applymRSU(context, &"slot/set", [slot, data])
