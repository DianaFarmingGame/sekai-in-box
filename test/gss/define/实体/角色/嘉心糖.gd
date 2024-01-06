extends GCharacter

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "嘉心糖"
	merge_props(sets, {
		&"power": 20,
		
		&"state_data": {
			&"combo": {
				&"cover": {
					&"cur_draw": &"combo",
					&"on_draw_loop": func (_sekai, this: Mono) -> void:
						await this.callm(&"state_to", &"idle")
						await this.callm(&"on_input_keys", this.getp(&"input_keys")),
				},
				&"on_enter": func (sekai: Sekai, this: Mono, pres) -> void:
					if pres != &"combo":
						await this.emitm(&"draw_reset")
					await sekai.timeout(0.1)
					var pos := Vector2(this.position.x, this.position.y)
					var pos_z := floori(this.position.z)
					var cur_dir = this.getp(&"cur_dir")
					var box := Rect2(-0.3, -0.2, 0.6, 0.4)
					box.position += pos + this.getp(&"cur_dir") * Vector2(0.2, 0)
					var tars := (await sekai.will_collide(box, pos_z)).filter(func (m): return m != this)
					await Async.array_map(tars, func (t: Mono): await t.applym(&"on_beated", [this.getp(&"power"), cur_dir])),
			},
		}
	})
	return sets
