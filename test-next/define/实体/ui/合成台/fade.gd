extends Node

func _ready():
	fade_out()

func fade_out():
	var fade = get_tree().create_tween()
	fade.tween_property(self, "modulate", Color(1, 1, 1, 0), 1)
	fade.tween_callback(self.queue_free)
