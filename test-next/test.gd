extends Control

func _ready() -> void:
	if not sekai.is_prepared: await sekai.prepared
	#await sekai.start_gikou("test", "res://test-next/test/dev-configurator/entry.gss.txt")
	#await sekai.start_gikou("map", "res://test-next/main/blank_entry.gss.txt")
	await sekai.enter_gikou("map")
