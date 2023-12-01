extends Node

@onready var sekai := $Sekai as Sekai

func _ready() -> void:
	var tree := get_tree()
	tree.auto_accept_quit = false
	tree.root.close_requested.connect(func ():
		$Sekai.queue_free()
		remove_child($Sekai)
		await tree.process_frame
		await tree.process_frame
		tree.quit())
	%SaveBtn.pressed.connect(func ():
		sekai.save_to_path("user://save.sekai"))
	%LoadBtn.pressed.connect(func ():
		sekai.load_from_path("user://save.sekai"))
