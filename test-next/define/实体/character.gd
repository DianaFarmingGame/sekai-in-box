class_name GCharacter extends GEntity

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GCharacter"
	merge_traits(sets, [TDefTarget, TSolid, TInput, TProcess, TMove, TPick, TState, TContainer, TPickable, TContactable, TUI])
	merge_props(sets, {
		&"on_input": Prop.puts({
			&"0:character": func (ctx: LisperContext, this: Mono, sets: InputSet) -> void:
				if this.getp(&"cur_state") != &"combo":
					var press := sets.pressings
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
				pass,
		}),
		
		&"on_pick": Prop.puts({
			&"0:character": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, pick: Variant, sets: InputSet) -> void:
				if pick is Mono:
					if sets.pressings.has(&"mono_select"):
						print(pick),
		}),
		
		&"on_solid_collide_all": Prop.puts({
			&"0:character": func (ctx: LisperContext, this: Mono, collides: Array) -> void:
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
	})
	return sets
