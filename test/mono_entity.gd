class_name MonoEntity extends Mono

var item: SekaiItem

func _ready() -> void:
	_clear_item()
	item = sekai.make_item()
	item.on_draw.connect(func (delta: float, time: float):
		if get_prop(&"visible"):
			var pos = get_prop(&"position")
			if pos != null: item.set_y(pos.y)
			call_method(&"draw", [delta, time]))
	sekai.add_child.call_deferred(item)

func _exit_tree() -> void:
	_clear_item()

func _clear_item() -> void:
	if item: sekai.remove_child(item)
	item = null

func get_item() -> SekaiItem:
	return item

func _process(delta: float) -> void:
	set_prop(&"position", get_prop(&"position") + Vector2(delta, delta))
