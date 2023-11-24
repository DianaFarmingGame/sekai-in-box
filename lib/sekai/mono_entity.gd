class_name MonoEntity extends Mono

var item: SekaiItem

func _into_sekai(psekai: Sekai) -> void:
	super._into_sekai(psekai)
	
	_clear_item()
	item = sekai.make_item()
	if get_prop(&"need_process"):
		item.on_process.connect(func ():
			if get_prop(&"processing"):
				call_method(&"process"))
	item.on_draw.connect(func ():
		if get_prop(&"visible"):
			var pos = get_prop(&"position")
			if pos != null: item.set_y(pos.y)
			call_method(&"draw"))
	sekai.add_child.call_deferred(item)

func _clear_item() -> void:
	if item: sekai.remove_child(item)
	item = null

func get_item() -> SekaiItem:
	return item
