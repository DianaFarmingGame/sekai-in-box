class_name MonoEntity extends Mono

var item: SekaiItem

func _into_sekai() -> void:
	super._into_sekai()
	
	_clear_item()
	item = sekai.make_item()
	if getp(&"need_process"):
		item.on_process.connect(func ():
			if getp(&"processing"):
				emitm(&"on_process"))
	item.on_draw.connect(func ():
		item.set_y(position.y + floorf(position.z) * 64)
		callm(&"on_draw", item))
	sekai.add_child.call_deferred(item)

func _outof_sekai() -> void:
	_clear_item()
	super._outof_sekai()

func to_data() -> Dictionary:
	return super.to_data()

func _clear_item() -> void:
	if item:
		sekai.remove_child(item)
		item.queue_free()
		item = null
