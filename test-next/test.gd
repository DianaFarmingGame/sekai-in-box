extends Control

func _ready() -> void:
	await sekai.start_gikou("test", "res://test-next/test/dev-next/entry.gss.txt")
