class_name GCharacter extends GEntity

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GCharacter"
	merge_traits(sets, [TDefTarget, TSolid, TInputAction, TProcess, TState, TContainer, TPickable])
	merge_props(sets, {
		&"name": "unnamed",
		&"max_speed": 3,
		&"touch_radius": 1,
		&"solid_route_zoffset": -1,
		
		&"cur_speed": Vector2(0, 0),
		&"cur_dir": -1,
		
		&"on_input_action": Prop.puts({
			&"0:character": func (ctx: LisperContext, this: Mono, all: Dictionary, press: Dictionary, _release) -> void:
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
								await ctx.call_method(this, action, [mono, this])
					elif press.has(&"combo"):
						await this.callm(ctx, &"state/to", &"combo")
					else:
						var dir := Vector2(0, 0)
						if all.has(&"ui_up"): dir += Vector2(0, -1)
						if all.has(&"ui_down"): dir += Vector2(0, 1)
						if all.has(&"ui_left"): dir += Vector2(-1, 0)
						if all.has(&"ui_right"): dir += Vector2(1, 0)
						var speed := dir.normalized() * 3
						this.setpF(ctx, &"cur_speed", speed)
						if speed == Vector2(0, 0):
							await this.callm(ctx, &"state/to", &"idle")
						else:
							await this.callm(ctx, &"state/to", &"walk")
				pass,
		}),
		
		&"on_move": Prop.puts({
			&"0:character": func (ctx: LisperContext, this: Mono) -> void:
				var collides := await this.emitm(ctx, &"solid_collide_all_by") as Array
				var drops := await Async.array_filter(collides, func (m): return await m.callm(ctx, &"group_in", &"drop"))
				for drop in drops:
					for item in drop.getp("contains"):
						if await this.callm(ctx, &"container/put", item):
							await drop.callm(ctx, &"container/pick", item)
					if drop.getp("contains").size() == 0:
						drop.destroy()
				pass,
		}),
		
		&"on_contains": func (ctx: LisperContext, this: Mono, contains: Array) -> Array:
			sekai.external_fns[&"itembox_update"].call(sekai, this, contains)
			return contains,
		
		&"on_cur_speed": func (ctx: LisperContext, this: Mono, speed: Vector2) -> Vector2:
			if speed.x < 0:
				this.setpW(ctx, &"cur_dir", -1)
			if speed.x > 0:
				this.setpW(ctx, &"cur_dir", 1)
			return speed,
		
		&"on_cur_dir": func (ctx: LisperContext, this: Mono, dir: float) -> float:
			if dir < 0:
				this.setp(&"flip_h", false)
			if dir > 0:
				this.setp(&"flip_h", true)
			return dir,
		
		&"face_to": func (ctx: LisperContext, this: Mono, target: Variant) -> void:
			var pos: Vector2 = target if target is Vector2 else Vector2(target.position.x, target.position.y)
			var dx := pos.x - this.position.x
			if dx < 0:
				this.setpW(ctx, &"cur_dir", -1)
			if dx > 0:
				this.setpW(ctx, &"cur_dir", 1),
		
		&"move_by": func (ctx: LisperContext, this: Mono, delta: Vector2) -> bool:
			return await this.applym(ctx, &"move_by_at_speed", [delta, this.getp(&"max_speed")]),
		
		&"move_by_at_speed": func (ctx: LisperContext, this: Mono, delta: Vector2, max_speed: float) -> bool:
			await this.callm(ctx, &"state/to", &"walk")
			var target := Vector2(this.position.x, this.position.y) + delta
			var blocked := false
			var block_cnt := 0
			while delta.length() > 0.1:
				var ppos := this.position
				var dt := this.item.get_delta_time() as float
				var speedv := delta / dt
				var speed := speedv.length()
				if speed > max_speed: speedv *= max_speed / speed
				this.setpF(ctx, &"cur_speed", speedv)
				await sekai.before_process
				delta = target - Vector2(this.position.x, this.position.y)
				if (this.position - ppos).length() < (max_speed * dt) * 0.1:
					block_cnt += 1
					if block_cnt > 5:
						blocked = true
						break
				else:
					block_cnt = 0
			this.setpF(ctx, &"cur_speed", Vector2(0, 0))
			await this.callm(ctx, &"state/to", &"idle")
			return not blocked,
		
		&"move_to": func (ctx: LisperContext, this: Mono, target: Variant) -> bool:
			return await this.applym(ctx, &"move_to_at_speed", [target, this.getp(&"max_speed")]),
		
		&"move_to_at_speed": func (ctx: LisperContext, this: Mono, target: Variant, max_speed: float) -> bool:
			var delta: Vector2
			var blocked := false
			var block_cnt := 0
			await this.callm(ctx, &"state/to", &"walk")
			if target is Vector2:
				delta = target - Vector2(this.position.x, this.position.y)
				while delta.length() > 0.1:
					var ppos := this.position
					var dt := this.item.get_delta_time() as float
					var speedv := delta / dt
					var speed := speedv.length()
					if speed > max_speed: speedv *= max_speed / speed
					this.setpF(ctx, &"cur_speed", speedv)
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
					this.setpF(ctx, &"cur_speed", speedv)
					await sekai.before_process
					delta = Vector2(target.position.x, target.position.y) - Vector2(this.position.x, this.position.y)
					if (this.position - ppos).length() < (max_speed * dt) * 0.1:
						block_cnt += 1
						if block_cnt > 5:
							blocked = true
							break
					else:
						block_cnt = 0
			this.setpF(ctx, &"cur_speed", Vector2(0, 0))
			await this.callm(ctx, &"state/to", &"idle")
			return not blocked,
		
		&"say_to": func (ctx: LisperContext, this: Mono, _target: Mono, meta_text, text = null) -> void:
			if text != null:
				await sekai.external_fns[&"dialog_say_to"].call(sekai, this, meta_text, text)
			else:
				await sekai.external_fns[&"dialog_say_to"].call(sekai, this, {}, meta_text),
		
		&"show_aside": func (ctx: LisperContext, this: Mono, meta_text, text = null) -> void:
			if text != null:
				await sekai.external_fns[&"dialog_show_aside"].call(sekai, this, meta_text, text)
			else:
				await sekai.external_fns[&"dialog_show_aside"].call(sekai, this, {}, meta_text),
		
		&"choose_single": Lisper.FnGDRaw( func (ctx: LisperContext, body: Array, comptime: bool) -> Variant:
			if comptime: return await ctx.compiles(body)
			var sekai := await ctx.exec(body[0]) as Sekai
			var this := await ctx.exec(body[1]) as Mono
			var meta = {}
			var title = null
			var patterns = null
			var meta_title = await ctx.exec(body[2])
			if meta_title is Dictionary:
				meta = meta_title
				title = await ctx.exec(body[3])
				patterns = body.slice(4)
			else:
				title = meta_title
				patterns = body.slice(3)
			var count := patterns.size() / 2 as int
			var choices := Array()
			choices.resize(count)
			var branches := Array()
			branches.resize(count)
			for i in count:
				choices[i] = ctx.exec_as_string(patterns[2 * i]) as String
				branches[i] = patterns[2 * i + 1] as Array
			var choose := await sekai.external_fns[&"dialog_choose_single"].call(sekai, this, meta, title, choices) as int
			return await ctx.exec(branches[choose])),
		
		&"dialog_to": Lisper.FnGDApply( func (ctx: LisperContext, args: Array) -> Variant:
			var vid = args[3]
			var dialog = ctx.get_var("*sekai*").dbs_get("行为", vid)
			return await ctx.call_fn(dialog, args.slice(0, 3))),
		
		&"check_bag_item": func(ctx: LisperContext, this: Mono, item: Dictionary) -> bool:
			var bag := this.getp(&"contains") as Array
			var total_item := {}
			for i in bag:
				var item_id = i.define.id
				var count := i.getp(&"stack_count") as int
				if total_item.has(item_id):
					total_item[item_id] += count
				else:
					total_item[item_id] = count
			
			var flag := true
			for i in item:
				if !total_item.get(i) or item[i] > total_item[i]:
					flag = false
				break
			
			return flag,

		&"put_item": func(ctx: LisperContext, this: Mono, item: Mono) -> bool:
			#TODO: 处理失败情况
			return await this.callm(ctx, &"container/put", item)
			,

		&"change_interact": func (ctx: LisperContext, this: Mono, action_id) -> void:
			var tmp = this.getp(&"actions")
			tmp[&"interact"] = sekai.dbs_get("行为", action_id)
			,

		&"init_state": &"idle",
		&"state_data": {
			&"idle": {
				&"cover": {
					&"cur_draw": &"idle",
				},
				&"on_enter": func (ctx: LisperContext, this: Mono, _pres) -> void:
					await this.emitm(ctx, &"draw/reset"),
			},
			&"walk": {
				&"cover": {
					&"cur_draw": &"walk",
					&"on_process": func (ctx: LisperContext, this: Mono, delta: float) -> void:
						var cur_speed := this.getp(&"cur_speed") as Vector2
						if cur_speed != Vector2(0, 0):
							var dpos := cur_speed * delta as Vector2
							await this.callm(ctx, &"solid_move", Vector3(dpos.x, 0, 0))
							await this.callm(ctx, &"solid_move", Vector3(0, dpos.y, 0)),
				},
				&"on_enter": func (ctx: LisperContext, this: Mono, _pres) -> void:
					await this.emitm(ctx, &"draw/reset"),
			},
		},
	})
	return sets
