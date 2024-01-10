class_name GCharacter extends GEntity

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GCharacter"
	merge_traits(sets, [TSolid, TInputAction, TProcess, TState, TContainer])
	var vprops := {
		&"name": "unnamed",
		&"max_speed": 3,
		&"touch_radius": 1,
		&"solid_route_zoffset": -1,
		
		&"cur_speed": Vector2(0, 0),
		&"cur_dir": -1,
		
		&"on_input_action": Prop.puts({
			&"0:character": func (sekai: Sekai, this: Mono, all: Dictionary, press: Dictionary, _release) -> void:
				if this.getp(&"cur_state") != &"combo":
					if press.has(&"dialog_confirm"):
						var mono = null
						var min_dis = INF
						for m in sekai.monos:
							if m is Mono and m != this:
								var dis := this.position.distance_squared_to(m.position)
								if dis < min_dis:
									min_dis = dis
									mono = m
						if mono != null and sqrt(min_dis) <= this.getp(&"touch_radius"):
							var action = mono.getp(&"actions").get(&"interact")
							if action != null:
								sekai.gss_ctx.call_fn(action, [sekai, mono, this])
					elif press.has(&"combo"):
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
		}),
		
		&"on_move": func (_sekai, this: Mono) -> void:
			var collides := await this.emitm(&"solid_collide_all_by") as Array
			var drops := await Async.array_filter(collides, func (m): return await m.callm(&"group_in", &"drop"))
			for drop in drops:
				for item in drop.getp("contains"):
					if await this.callm(&"container_put", item):
						await drop.callm(&"container_pick", item)
				if drop.getp("contains").size() == 0:
					drop.destroy()
					
			pass,
		
		&"on_contains": func (sekai: Sekai, this: Mono, contains: Array) -> Array:
			sekai.external_fns[&"itembox_update"].call(sekai, this, contains)
			return contains,
		
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
			return await this.applym(&"move_by_at_speed", [delta, this.getp(&"max_speed")]),
		
		&"move_by_at_speed": func (sekai: Sekai, this: Mono, delta: Vector2, max_speed: float) -> bool:
			await this.callm(&"state_to", &"walk")
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
			await this.callm(&"state_to", &"idle")
			return not blocked,
		
		&"move_to": func (_sekai, this: Mono, target: Variant) -> bool:
			return await this.applym(&"move_to_at_speed", [target, this.getp(&"max_speed")]),
		
		&"move_to_at_speed": func (sekai: Sekai, this: Mono, target: Variant, max_speed: float) -> bool:
			var delta: Vector2
			var blocked := false
			var block_cnt := 0
			await this.callm(&"state_to", &"walk")
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
			await this.callm(&"state_to", &"idle")
			return not blocked,
		
		&"say_to": func (sekai: Sekai, this: Mono, _target: Mono, meta_text, text = null) -> void:
			if text != null:
				await sekai.external_fns[&"dialog_say_to"].call(sekai, this, meta_text, text)
			else:
				await sekai.external_fns[&"dialog_say_to"].call(sekai, this, {}, meta_text),
		
		&"show_aside": func (sekai: Sekai, this: Mono, meta_text, text = null) -> void:
			if text != null:
				await sekai.external_fns[&"dialog_show_aside"].call(sekai, this, meta_text, text)
			else:
				await sekai.external_fns[&"dialog_show_aside"].call(sekai, this, {}, meta_text),
		
		&"choose_single": func (sekai: Sekai, this: Mono, meta_arg1, arg1, arg2 = null) -> int:
			if arg2 != null:
				return await sekai.external_fns[&"dialog_choose_single"].call(sekai, this, meta_arg1, arg1, arg2)
			else:
				return await sekai.external_fns[&"dialog_choose_single"].call(sekai, this, {}, meta_arg1, arg1),
		
		&"init_state": &"idle",
		&"state_data": {
			&"idle": {
				&"cover": {
					&"cur_draw": &"idle",
				},
				&"on_enter": func (_sekai, this: Mono, _pres) -> void:
					await this.emitm(&"draw_reset"),
			},
			&"walk": {
				&"cover": {
					&"cur_draw": &"walk",
					&"on_process": func (_sekai, this: Mono) -> void:
						var cur_speed := this.getp(&"cur_speed") as Vector2
						if cur_speed != Vector2(0, 0):
							var delta := this.item.get_delta_time() as float
							var dpos := cur_speed * delta as Vector2
							await this.callm(&"solid_move", Vector3(dpos.x, 0, 0))
							await this.callm(&"solid_move", Vector3(0, dpos.y, 0)),
				},
				&"on_enter": func (_sekai, this: Mono, _pres) -> void:
					await this.emitm(&"draw_reset"),
			},
		}
	}
	merge_props(sets, vprops)
	merge_props(sets, {
		&"actions": Prop.mergep({
			&"face_to": Lisper.FuncGDCall(vprops[&"face_to"]),
			&"move_by": Lisper.FuncGDCall(vprops[&"move_by"]),
			&"move_by_at_speed": Lisper.FuncGDCall(vprops[&"move_by_at_speed"]),
			&"move_to": Lisper.FuncGDCall(vprops[&"move_to"]),
			&"move_to_at_speed": Lisper.FuncGDCall(vprops[&"move_to_at_speed"]),
			&"say_to": Lisper.FuncGDCall(vprops[&"say_to"]),
			&"show_aside": Lisper.FuncGDCall(vprops[&"show_aside"]),
			&"choose_single": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> Variant:
				var sekai := await ctx.exec_node(body[0]) as Sekai
				var this := await ctx.exec_node(body[1]) as Mono
				var meta = {}
				var title = null
				var patterns = null
				var meta_title = await ctx.exec_node(body[2])
				if meta_title is Dictionary:
					meta = meta_title
					title = await ctx.exec_node(body[3])
					patterns = body.slice(4)
				else:
					title = meta_title
					patterns = body.slice(3)
				@warning_ignore("integer_division")
				var count := patterns.size() / 2 as int
				var choices := Array()
				choices.resize(count)
				var branches := Array()
				branches.resize(count)
				for i in count:
					choices[i] = ctx.exec_as_string(patterns[2 * i]) as String
					branches[i] = patterns[2 * i + 1] as Array
				var choose := await vprops[&"choose_single"].call(sekai, this, meta, title, choices) as int
				return await ctx.exec_node(branches[choose])),
			&"dialog_to": Lisper.FuncGDRaw( func (ctx: LisperContext, body: Array) -> Variant:
				var vid = await ctx.exec_node(body[3])
				var dialog = ctx.get_var(&"Dialogs")[vid]
				return await ctx.call_rawfn(dialog, body.slice(0, 3))),
		}),
	})
	return sets
