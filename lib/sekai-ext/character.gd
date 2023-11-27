class_name GCharacter extends MonoDefine

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	merge_props(sets, {
		&"state": &"normal",
		&"cur_speed": Vector2(0, 0),
		
		&"process": func (sekai: Sekai, this: Mono) -> void:
			var cur_speed := this.get_prop(&"cur_speed") as Vector2
			if cur_speed != Vector2(0, 0):
				var delta := this.item.get_delta_time() as float
				var pos_z := floori(this.position.z)
				var pos := Vector2(this.position.x, this.position.y)
				var dpos := this.get_prop(&"cur_speed") * delta as Vector2
				if sekai.can_pass(Rect2(pos.x + dpos.x, pos.y, 0, 0).grow(0.25), pos_z):
					pos.x += dpos.x
				if sekai.can_pass(Rect2(pos.x, pos.y + dpos.y, 0, 0).grow(0.25), pos_z):
					pos.y += dpos.y
				this.position = Vector3(pos.x, pos.y, this.position.z),
		&"draw": func (sekai: Sekai, this: Mono) -> void:
			var item := this.item as SekaiItem
			var pos := Vector2(this.position.x, this.position.y)
			item.pen_set_transform(pos, 0, Vector2(1, 0.4))
			item.draw_circle(Vector2(0, 0), 0.25, 0x00000055)
			item.pen_clear_transform()
			TVisible.draw(sekai, this),
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
				this.call_method(&"reset_to_drawer", &"normal")
			else:
				this.call_method(&"reset_to_drawer", &"walk")
			return keys,
	})
	merge_traits(sets, [TVisible, TInputKey, TProcess])
	return super.do_merge(sets)
