extends Node2D

func _ready() -> void:
	var tree := get_tree()
	tree.auto_accept_quit = false
	tree.root.close_requested.connect(func ():
		$Sekai.queue_free()
		remove_child($Sekai)
		await tree.process_frame
		await tree.process_frame
		tree.quit())
