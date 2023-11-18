class_name MonoLike extends Node

var sekai: Sekai

func _enter_tree() -> void:
	sekai = get_parent() as Sekai

func draw() -> void: pass
