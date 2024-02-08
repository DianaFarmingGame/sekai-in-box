extends Control

var this: Mono
var context: LisperContext
var control: SekaiControl

func _ready() -> void:
	var node := preload("view.tscn").instantiate()
	node.this = this
	node.context = context
	node.control = control
	add_child(node)
