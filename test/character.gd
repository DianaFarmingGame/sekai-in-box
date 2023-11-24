class_name GCharacter extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	merge_traits(sets, [TVisible, TInputKey, TProcess])
	merge_props(sets, {
		&"position": Vector2(0, 0),
		&"state": &"normal",
		&"cur_speed": Vector2(0, 0),
	})
	merge_methods(sets, {
		&"process": func (_sekai, this: Mono) -> void:
			var delta := this.get_item().get_delta_time()
			this.set_prop(&"position", this.get_prop(&"position") + this.get_prop(&"cur_speed") * delta),
	})
	merge_watchers(sets, {
		&"input_keys": func (_sekai, this: Mono, _prev, keys: Dictionary):
			var dir := Vector2(0, 0)
			if keys.get(&"Up"): dir += Vector2(0, -1)
			if keys.get(&"Down"): dir += Vector2(0, 1)
			if keys.get(&"Left"): dir += Vector2(-1, 0)
			if keys.get(&"Right"): dir += Vector2(1, 0)
			var speed := dir.normalized() * 4
			this.set_prop(&"cur_speed", speed)
			if speed.x < 0: this.set_prop(&"flip_h", true)
			if speed.x > 0: this.set_prop(&"flip_h", false)
			if speed == Vector2(0, 0):
				this.call_method(&"reset_to_drawer", [&"normal"])
			else:
				this.call_method(&"reset_to_drawer", [&"walk"])
			return keys,
	})
	return super.do_merge(sets)
