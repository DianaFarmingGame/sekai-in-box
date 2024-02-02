extends Control

func _ready() -> void:
	sekai.start_gikou("test", "res://test-next/test/dev-ls/entry.gss.txt")
	$SekaiControl.target = sekai.gikou.getp(&"player")
