class_name MonoEntity extends Mono

var item: SekaiItem
var debug_item: SekaiItem

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
		item.pen_clear_transform()
		callm(&"on_draw", item))
	if ProjectSettings.get_setting(&"sekai/debug_draw"):
		debug_item = sekai.make_item()
		debug_item.on_draw.connect(func ():
			debug_item.set_y(position.y + floorf(position.z) * 64 + 4096)
			debug_item.pen_clear_transform()
			callm(&"on_draw_debug", debug_item))
		sekai.add_child.call_deferred(debug_item)
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
	if debug_item:
		sekai.remove_child(debug_item)
		debug_item.queue_free()
		debug_item = null
