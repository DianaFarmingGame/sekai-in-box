@tool
extends EditorPlugin

func _enter_tree() -> void:
	add_autoload_singleton("sekai", "res://lib/sekai/sekai.gd")
	ProjectSettings.add_property_info({
		"name": "sekai/define_entry",
		"type": TYPE_STRING,
		"hint": PROPERTY_HINT_FILE,
		"hint_string": "*.gsm.gd,*.gss.txt",
	})

func _exit_tree() -> void:
	remove_autoload_singleton("sekai")
