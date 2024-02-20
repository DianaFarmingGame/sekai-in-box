extends Control

func _ready() -> void:
	if not sekai.is_prepared: await sekai.prepared
	await sekai.start_gikou("test", "res://test-next/test/demo/entry.gss.txt")
