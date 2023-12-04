class_name GCharacter extends GEntity

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	merge_traits(sets, [TCollisible, TInputKey, TProcess, TState])
	merge_props(sets, {
		&"cur_speed": Vector2(0, 0),
		&"cur_dir": 1,
		&"power": 20,
		&"acc_damage": 0,
		&"down_threshold": 40,
		
		&"on_draw": Prop.puts({
			&"-1:charactor_shadow": func (_sekai, this: Mono, item: SekaiItem) -> void:
				var pos := Vector2(this.position.x, this.position.y)
				item.pen_set_transform(pos, 0, Vector2(1, 0.4))
				item.draw_circle(Vector2(0, 0), 0.25, 0x00000055)
				item.pen_clear_transform(),
		}),
		&"on_process": Prop.puts({
			&"0:acc_damage_recover": func (_sekai, this: Mono) -> void:
				var delta := this.item.get_delta_time() as float
				var acc_damage := this.getp(&"acc_damage") as float
				acc_damage = maxf(0, acc_damage - delta * 20)
				this.setp(&"acc_damage", acc_damage),
		}),
		&"on_input_keys": func (_sekai, this: Mono, keys: Dictionary) -> Dictionary:
			if this.getp(&"cur_state") != &"combo":
				if keys.get(&"Z"):
					this.callm(&"state_to", &"combo")
				else:
					var dir := Vector2(0, 0)
					if keys.get(&"Up"): dir += Vector2(0, -1)
					if keys.get(&"Down"): dir += Vector2(0, 1)
					if keys.get(&"Left"): dir += Vector2(-1, 0)
					if keys.get(&"Right"): dir += Vector2(1, 0)
					var speed := dir.normalized() * 4
					this.setp(&"cur_speed", speed)
					if speed.x < 0:
						this.setp(&"flip_h", true)
						this.setp(&"cur_dir", -1)
					if speed.x > 0:
						this.setp(&"flip_h", false)
						this.setp(&"cur_dir", 1)
					if speed == Vector2(0, 0):
						this.callm(&"state_to", &"idle")
					else:
						this.callm(&"state_to", &"walk")
			return keys,
		&"on_beated": func (_sekai, this: Mono, damage: int, dir: float) -> void:
			if this.getp(&"cur_state") != &"down":
				var acc_damage = this.getp(&"acc_damage") + damage
				if acc_damage < this.getp(&"down_threshold"):
					this.setp(&"flip_h", not dir < 0)
					this.setp(&"cur_dir", -dir)
					this.callm(&"state_to", &"beated")
					this.emitm(&"draw_reset")
				else:
					this.setp(&"flip_h", not dir < 0)
					this.setp(&"cur_dir", -dir)
					this.callm(&"state_to", &"down")
				this.setp(&"acc_damage", acc_damage),
		
		&"collision_box": Rect2(-0.2, -0.1, 0.4, 0.2),
		
		&"init_state": &"idle",
		&"state_data": {
			&"idle": {
				&"cover": {
					&"cur_draw": &"idle",
				},
				&"on_enter": func (_sekai, this: Mono, _pres):
					this.emitm(&"draw_reset"),
			},
			&"walk": {
				&"cover": {
					&"cur_draw": &"walk",
					&"on_process": func (sekai: Sekai, this: Mono) -> void:
						var cur_speed := this.getp(&"cur_speed") as Vector2
						if cur_speed != Vector2(0, 0):
							var delta := this.item.get_delta_time() as float
							var pos_z := floori(this.position.z)
							var pos := Vector2(this.position.x, this.position.y)
							var dpos := cur_speed * delta as Vector2
							var box := this.getp(&"collision_box") as Rect2
							box.position += pos + Vector2(dpos.x, 0)
							if sekai.will_collide(box, pos_z).filter(func (m): return m != this).size() == 0 \
							and sekai.will_route(box.get_center(), pos_z - 1).size() > 0:
								pos.x += dpos.x
							else:
								box.position -= Vector2(dpos.x, 0)
							box.position += Vector2(0, dpos.y)
							if sekai.will_collide(box, pos_z).filter(func (m): return m != this).size() == 0 \
							and sekai.will_route(box.get_center(), pos_z - 1).size() > 0:
								pos.y += dpos.y
							this.position = Vector3(pos.x, pos.y, this.position.z),
				},
				&"on_enter": func (_sekai, this: Mono, _pres) -> void:
					this.emitm(&"draw_reset"),
			},
			&"combo": {
				&"cover": {
					&"cur_draw": &"combo",
					&"on_draw_loop": func (_sekai, this: Mono) -> void:
						this.callm(&"state_to", &"idle")
						this.callm(&"on_input_keys", this.getp(&"input_keys")),
				},
				&"on_enter": func (sekai: Sekai, this: Mono, pres) -> void:
					if pres != &"combo":
						this.emitm(&"draw_reset")
					await sekai.timeout(0.1)
					var pos := Vector2(this.position.x, this.position.y)
					var pos_z := floori(this.position.z)
					var cur_dir = this.getp(&"cur_dir")
					var box := Rect2(-0.3, -0.2, 0.6, 0.4)
					box.position += pos + this.getp(&"cur_dir") * Vector2(0.2, 0)
					var tars := sekai.will_collide(box, pos_z).filter(func (m): return m != this)
					tars.map(func (t: Mono): t.applym(&"on_beated", [this.getp(&"power"), cur_dir])),
			},
			&"beated": {
				&"cover": {
					&"cur_draw": &"beated",
					&"on_process": func (sekai: Sekai, this: Mono) -> void:
						var speed := this.getp(&"cur_dir") * Vector2(-0.1, 0) as Vector2
						var delta := this.item.get_delta_time() as float
						var pos_z := floori(this.position.z)
						var pos := Vector2(this.position.x, this.position.y)
						var dpos := speed * delta as Vector2
						var box := this.getp(&"collision_box") as Rect2
						box.position += pos + Vector2(dpos.x, 0)
						if sekai.will_collide(box, pos_z).filter(func (m): return m != this).size() == 0 \
						and sekai.will_route(box.get_center(), pos_z - 1).size() > 0:
							pos.x += dpos.x
						else:
							box.position -= Vector2(dpos.x, 0)
						box.position += Vector2(0, dpos.y)
						if sekai.will_collide(box, pos_z).filter(func (m): return m != this).size() == 0 \
						and sekai.will_route(box.get_center(), pos_z - 1).size() > 0:
							pos.y += dpos.y
						this.position = Vector3(pos.x, pos.y, this.position.z),
					&"on_draw_loop": func (_sekai, this: Mono) -> bool:
						this.callm(&"state_to", &"idle")
						this.callm(&"on_input_keys", this.getp(&"input_keys"))
						return true,
				},
				&"on_enter": func (_sekai, this: Mono, _pres) -> void:
					this.emitm(&"draw_reset"),
			},
			&"down": {
				&"cover": {
					&"cur_draw": &"down",
					&"on_process": func (_sekai, this: Mono) -> void:
						if this.getp(&"acc_damage") == 0:
							this.callm(&"state_to", &"up"),
					&"on_draw_loop": func (_sekai, this: Mono) -> bool:
						this.callm(&"draw_to", &"down_static")
						return true,
				},
				&"on_enter": func (_sekai, this: Mono, _pres) -> void:
					this.callm(&"draw_to", &"down")
					this.emitm(&"draw_reset"),
			},
			&"up": {
				&"cover": {
					&"cur_draw": &"up",
					&"on_draw_loop": func (_sekai, this: Mono) -> bool:
						this.callm(&"state_to", &"idle")
						return true,
				},
				&"on_enter": func (_sekai, this: Mono, _pres) -> void:
					this.emitm(&"draw_reset"),
			}
		}
	})
	return sets
