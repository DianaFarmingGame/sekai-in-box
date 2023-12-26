class_name GCharacter extends GEntity

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	merge_traits(sets, [TCollisible, TInputAction, TProcess, TState])
	merge_props(sets, {
		&"name": "unnamed",
		&"max_speed": 3,
		&"touch_radius": 1,
		
		&"cur_speed": Vector2(0, 0),
		&"cur_dir": -1,
		
		&"on_input_action": func (_sekai, this: Mono, all: Dictionary, press: Dictionary, _release) -> void:
			if this.getp(&"cur_state") != &"combo":
				if press.has(&"combo"):
					this.callm(&"state_to", &"combo")
				else:
					var dir := Vector2(0, 0)
					if all.has(&"ui_up"): dir += Vector2(0, -1)
					if all.has(&"ui_down"): dir += Vector2(0, 1)
					if all.has(&"ui_left"): dir += Vector2(-1, 0)
					if all.has(&"ui_right"): dir += Vector2(1, 0)
					var speed := dir.normalized() * 3
					this.setp(&"cur_speed", speed)
					if speed == Vector2(0, 0):
						this.callm(&"state_to", &"idle")
					else:
						this.callm(&"state_to", &"walk")
			pass,
		
		&"on_cur_speed": func (_sekai, this: Mono, speed: Vector2) -> Vector2:
			if speed.x < 0:
				this.setp(&"cur_dir", -1)
			if speed.x > 0:
				this.setp(&"cur_dir", 1)
			return speed,
		
		&"on_cur_dir": func (_sekai, this: Mono, dir: float) -> float:
			if dir < 0:
				this.setp(&"flip_h", false)
			if dir > 0:
				this.setp(&"flip_h", true)
			return dir,
		
		&"face_to": func (_sekai, this: Mono, target: Variant) -> void:
			var pos: Vector2 = target if target is Vector2 else Vector2(target.position.x, target.position.y)
			var dx := pos.x - this.position.x
			if dx < 0:
				this.setp(&"cur_dir", -1)
			if dx > 0:
				this.setp(&"cur_dir", 1),
		
		&"move_by": func (_sekai, this: Mono, delta: Vector2) -> bool:
			return await this.applymA(&"move_by_at_speed", [delta, this.getp(&"max_speed")]),
		
		&"move_by_at_speed": func (sekai: Sekai, this: Mono, delta: Vector2, max_speed: float) -> bool:
			this.callm(&"state_to", &"walk")
			var target := Vector2(this.position.x, this.position.y) + delta
			var blocked := false
			var block_cnt := 0
			while delta.length() > 0.1:
				var ppos := this.position
				var dt := this.item.get_delta_time() as float
				var speedv := delta / dt
				var speed := speedv.length()
				if speed > max_speed: speedv *= max_speed / speed
				this.setp(&"cur_speed", speedv)
				await sekai.before_process
				delta = target - Vector2(this.position.x, this.position.y)
				if (this.position - ppos).length() < (max_speed * dt) * 0.1:
					block_cnt += 1
					if block_cnt > 5:
						blocked = true
						break
				else:
					block_cnt = 0
			this.setp(&"cur_speed", Vector2(0, 0))
			this.callm(&"state_to", &"idle")
			return not blocked,
		
		&"move_to": func (_sekai, this: Mono, target: Variant) -> bool:
			return await this.applymA(&"move_to_at_speed", [target, this.getp(&"max_speed")]),
		
		&"move_to_at_speed": func (sekai: Sekai, this: Mono, target: Variant, max_speed: float) -> bool:
			var delta: Vector2
			var blocked := false
			var block_cnt := 0
			this.callm(&"state_to", &"walk")
			if target is Vector2:
				delta = target - Vector2(this.position.x, this.position.y)
				while delta.length() > 0.1:
					var ppos := this.position
					var dt := this.item.get_delta_time() as float
					var speedv := delta / dt
					var speed := speedv.length()
					if speed > max_speed: speedv *= max_speed / speed
					this.setp(&"cur_speed", speedv)
					await sekai.before_process
					delta = target - Vector2(this.position.x, this.position.y)
					if (this.position - ppos).length() < (max_speed * dt) * 0.1:
						block_cnt += 1
						if block_cnt > 5:
							blocked = true
							break
					else:
						block_cnt = 0
			else:
				var touch_radius := this.getp(&"touch_radius") as float
				delta = Vector2(target.position.x, target.position.y) - Vector2(this.position.x, this.position.y)
				while delta.length() > touch_radius:
					var ppos := this.position
					var dt := this.item.get_delta_time() as float
					var speedv := delta / dt
					var speed := speedv.length()
					if speed > max_speed: speedv *= max_speed / speed
					this.setp(&"cur_speed", speedv)
					await sekai.before_process
					delta = Vector2(target.position.x, target.position.y) - Vector2(this.position.x, this.position.y)
					if (this.position - ppos).length() < (max_speed * dt) * 0.1:
						block_cnt += 1
						if block_cnt > 5:
							blocked = true
							break
					else:
						block_cnt = 0
			this.setp(&"cur_speed", Vector2(0, 0))
			this.callm(&"state_to", &"idle")
			return not blocked,
		
		&"say_to": func (sekai: Sekai, this: Mono, _target: Mono, text: String) -> void:
			await sekai.external_fns[&"show_dialog"].call(sekai, this, text),
		
		&"init_state": &"idle",
		&"state_data": {
			&"idle": {
				&"cover": {
					&"cur_draw": &"idle",
				},
				&"on_enter": func (_sekai, this: Mono, _pres) -> void:
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
		}
	})
	return sets
