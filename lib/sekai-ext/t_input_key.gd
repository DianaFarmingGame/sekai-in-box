class_name TInputKey extends MonoTrait

var id := &"input_key"

var props := {
	&"input_keys": {},
}

var methods := {
	&"input_key": func (sekai: Sekai, this: Mono, event: InputEventKey) -> void:
		if event.echo == false:
			var pre_keys := this.get_prop(&"input_keys") as Dictionary
			var code := StringName(event.as_text_keycode())
			if event.pressed and not pre_keys.get(code):
				var keys = pre_keys.duplicate()
				keys[code] = true
				this.set_prop(&"input_keys", keys)
			elif pre_keys.get(code):
				var keys = pre_keys.duplicate()
				keys.erase(code)
				this.set_prop(&"input_keys", keys)
		sekai.get_viewport().set_input_as_handled(),
}
