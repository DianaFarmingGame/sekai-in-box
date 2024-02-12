extends Control

func _ready() -> void:
	# await sekai.prepared
	await sekai.start_gikou("test", "res://test-next/test/demo/entry.gss.txt")
