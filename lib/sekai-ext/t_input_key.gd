class_name TInputKey extends MonoTrait

var id := &"input_key"

var props := {
	&"input_keys": {},
	
	&"on_input_key": func (sekai: Sekai, this: Mono, event: InputEventKey) -> void:
		if event.echo == false:
			var pre_keys := this.getp(&"input_keys") as Dictionary
			var code := StringName(event.as_text_keycode().split('+')[-1])
			if event.pressed and not pre_keys.get(code):
				var keys = pre_keys.duplicate()
				keys[code] = true
				this.setp(&"input_keys", keys)
			elif pre_keys.get(code):
				var keys = pre_keys.duplicate()
				keys.erase(code)
				this.setp(&"input_keys", keys)
		sekai.get_viewport().set_input_as_handled(),
}