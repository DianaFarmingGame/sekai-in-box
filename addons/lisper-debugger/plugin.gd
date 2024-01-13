@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("LisperDebugger", "res://addons/lisper-debugger/lisper_debugger.tscn")

func _exit_tree() -> void:
	remove_autoload_singleton("LisperDebugger")
