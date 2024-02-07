extends Control

const tags := [
	"神様思考中...",
	"神様俯视中...",
	"神様犹豫中...",
	"神様观察中...",
]

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	%Tag.text = tags[randi_range(0, tags.size() - 1)]


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
