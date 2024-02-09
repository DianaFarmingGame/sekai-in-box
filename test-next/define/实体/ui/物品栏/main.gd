extends Control

var this: Mono
var context: LisperContext
var control: SekaiControl

func _ready() -> void:
	await this.applymRSU(context, &"inventory/open", [control, this])
