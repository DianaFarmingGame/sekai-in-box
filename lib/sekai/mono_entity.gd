class_name MonoEntity extends Mono

var item: SekaiItem

func _into_sekai(psekai: Sekai) -> void:
	super._into_sekai(psekai)
	
	position = get_prop(&"position")
	
	_clear_item()
	item = sekai.make_item()
	if get_prop(&"need_process"):
		item.on_process.connect(func ():
			if get_prop(&"processing"):
				call_method(&"process"))
	item.on_draw.connect(func ():
		if get_prop(&"visible"):
			item.set_y(position.y + floorf(position.z) * 64)
			call_method(&"draw"))
	sekai.add_child.call_deferred(item)

func _outof_sekai() -> void:
	_clear_item()
	super._outof_sekai()

func _clear_item() -> void:
	if item:
		sekai.remove_child(item)
		item.queue_free()
		item = null
