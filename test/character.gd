class_name GCharacter extends GEntity

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	merge_traits(sets, [TInputKey, TProcess])
	merge_props(sets, {
		&"state": &"normal",
		&"cur_speed": Vector2(0, 0),
		
		&"process": func (sekai: Sekai, this: Mono) -> void:
			var cur_speed := this.getp(&"cur_speed") as Vector2
			if cur_speed != Vector2(0, 0):
				var delta := this.item.get_delta_time() as float
				var pos_z := floori(this.position.z)
				var pos := Vector2(this.position.x, this.position.y)
				var dpos := this.getp(&"cur_speed") * delta as Vector2
				if sekai.can_pass(Rect2(pos.x + dpos.x, pos.y, 0, 0).grow(0.25), pos_z):
					pos.x += dpos.x
				if sekai.can_pass(Rect2(pos.x, pos.y + dpos.y, 0, 0).grow(0.25), pos_z):
					pos.y += dpos.y
				this.position = Vector3(pos.x, pos.y, this.position.z),
		&"draw": Prop.puts({
			&"-1.charactor_shadow": func (_sekai, this: Mono, item: SekaiItem) -> void:
				var pos := Vector2(this.position.x, this.position.y)
				item.pen_set_transform(pos, 0, Vector2(1, 0.4))
				item.draw_circle(Vector2(0, 0), 0.25, 0x00000055)
				item.pen_clear_transform(),
		}),
		&"on_input_keys": func (_sekai, this: Mono, keys: Dictionary):
			var dir := Vector2(0, 0)
			if keys.get(&"Up"): dir += Vector2(0, -1)
			if keys.get(&"Down"): dir += Vector2(0, 1)
			if keys.get(&"Left"): dir += Vector2(-1, 0)
			if keys.get(&"Right"): dir += Vector2(1, 0)
			var speed := dir.normalized() * 4
			this.setp(&"cur_speed", speed)
			if speed.x < 0: this.setp(&"flip_h", true)
			if speed.x > 0: this.setp(&"flip_h", false)
			if speed == Vector2(0, 0):
				this.callm(&"reset_to_draw", &"normal")
			else:
				this.callm(&"reset_to_draw", &"walk")
			return keys,
	})
	return sets
