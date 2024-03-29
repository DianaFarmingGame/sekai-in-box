class_name Chunk extends Box

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "Chunk"
	ref = 3
	id = &"chunk"
	merge_traits(sets, [TPosition, TWithLayer, TDrawable, TPickable])
	merge_props(sets, {
		&"chunk_size": Vector2(0, 0),
		&"chunk_cell": Vector3(1, 1, 1),
		&"chunk_data": [-1],
		&"need_process": true,
		
		&"chunk_mat": null,
		
		&"chunk/set": func (ctx: LisperContext, this: Mono, pos: Vector2, ref_id: Variant) -> void:
			var offset := this.position
			var data := this.getp(&"chunk_data") as Array
			var size := this.getp(&"chunk_size") as Vector2
			var cell := this.getp(&"chunk_cell") as Vector3
			if data.size() != size.x * size.y:
				var ndata := []
				ndata.resize(size.x * size.y as int)
				for i in ndata.size():
					ndata[i] = data[i % data.size()]
				data = ndata
				this.setpB(&"chunk_data", data)
			var ref := sekai.get_define(ref_id).ref as int
			if data[(pos.y * size.x + pos.x) as int] == ref: return
			data[(pos.y * size.x + pos.x) as int] = ref
			var mono := sekai.make_mono(ref)
			mono.position = Vector3(pos.x, pos.y, 0) * cell + offset
			mono.root = this
			var mat := this.getp(&"chunk_mat") as Array
			var contains := this.getp(&"contains") as Array
			var prev = mat[pos.y][pos.x]
			mat[pos.y][pos.x] = mono
			if prev != null:
				contains.erase(prev)
				(prev as Mono)._outof_container()
			contains.append(mono)
			#await mono._into_container(ctx, this)
			await this.get_hako().callmRSU(ctx, &"update_region", AABB(Vector3(pos.x, pos.y, 0) + this.position, Vector3()).grow(1))
			var layer_data := this.getp(&"layer_data") as Dictionary
			for ctrl in layer_data.keys():
				Chunk.update_control(ctx, this, ctrl)
			for layers in layer_data.values():
				layers[str(pos.y as int)].queue_redraw()
			this.setpBW(ctx, &"need_process", true),
		&"chunk/remove": func (ctx: LisperContext, this: Mono, pos: Vector2) -> void:
			var data := this.getp(&"chunk_data") as Array
			var size := this.getp(&"chunk_size") as Vector2
			if data.size() != size.x * size.y:
				var ndata := []
				ndata.resize(size.x * size.y as int)
				for i in ndata.size():
					ndata[i] = data[i % data.size()]
				data = ndata
				this.setpB(&"chunk_data", data)
			if data[(pos.y * size.x + pos.x) as int] == -1: return
			data[(pos.y * size.x + pos.x) as int] = -1
			var mat := this.getp(&"chunk_mat") as Array
			var contains := this.getp(&"contains") as Array
			var prev = mat[pos.y][pos.x]
			mat[pos.y][pos.x] = null
			if prev != null:
				contains.erase(prev)
				(prev as Mono)._outof_container()
			await this.get_hako().callmRSU(ctx, &"update_region", AABB(Vector3(pos.x, pos.y, 0) + this.position, Vector3()).grow(1))
			var layer_data := this.getp(&"layer_data") as Dictionary
			for ctrl in layer_data.keys():
				Chunk.update_control(ctx, this, ctrl)
			for layers in layer_data.values():
				layers[str(pos.y as int)].queue_redraw()
			this.setpBW(ctx, &"need_process", true),
		&"chunk/fill": func (ctx: LisperContext, this: Mono, ref: int) -> void:
			this.setpB(&"chunk_data", [ref])
			Chunk.rebuild_mat(ctx, this),
		&"collect_by_pos": func (ctx: LisperContext, this: Mono, pos: Vector3) -> Mono:
			var offset := this.position
			var cell := this.getp(&"chunk_cell") as Vector3
			var size := this.getp(&"chunk_size") as Vector2
			var posi = Vector3i((pos - offset) / cell)
			if 0 <= posi.x and posi.x < size.x and 0 <= posi.y and posi.y < size.y:
				var mat = this.getp(&"chunk_mat")
				if mat != null:
					return mat[posi.y][posi.x]
				else:
					var data := this.getp(&"chunk_data") as Array
					var i := (posi.y * size.x + posi.x) as int
					var rid = data[i % data.size()]
					if rid != -1:
						return sekai.make_mono(rid)
					else:
						return null
			else:
				return null,
		&"collect_by_region": func (ctx: LisperContext, this: Mono, region: AABB) -> Variant:
			var offset := this.position
			if region.position.z <= offset.z and offset.z <= region.end.z:
				var cell := this.getp(&"chunk_cell") as Vector3
				var size := this.getp(&"chunk_size") as Vector2
				var spos := (region.position - offset) / cell
				var epos := (region.end - offset) / cell
				var mat = this.getp(&"chunk_mat")
				var results := []
				for ix in size.x:
					if spos.x <= ix and ix <= epos.x:
						for iy in size.y:
							if spos.y <= iy and iy <= epos.y:
								if mat != null:
									if mat[iy][ix] != null:
										results.append(mat[iy][ix])
								else:
									var data := this.getp(&"chunk_data") as Array
									var i := (iy * size.x + ix) as int
									var rid = data[i % data.size()]
									if rid != -1:
										results.append(sekai.make_mono(rid))
				if results.size() > 0:
					return results
				else:
					return null
			return null,
		&"render_box_intersects": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, box: Rect2) -> bool:
			var rbox = this.getp(&"_c_render_box")
			if rbox == null:
				var offset := this.position
				var cell := this.getp(&"chunk_cell") as Vector3
				var size := this.getp(&"chunk_size") as Vector2
				var ratio_yz := ctrl.unit_size.y / ctrl.unit_size.z
				rbox = Rect2(Vector2(offset.x, offset.y - offset.z * ratio_yz), size * Vector2(cell.x, cell.y))
				this.setpB(&"_c_render_box", rbox)
			return rbox.intersects(box),
		
		
		
		&"on_process": Prop.Stack({
			&"0:chunk": func (ctx: LisperContext, this: Mono, _delta) -> void:
				if this.getp(&"need_process"):
					var need_process := false
					var mat := this.getp(&"chunk_mat") as Array
					var layer_data := this.getp(&"layer_data") as Dictionary
					for y in mat.size():
						var need_redraw = mat[y].any(func (m): return m != null and not m.inited)
						if need_redraw:
							need_process = true
							for layers in layer_data.values():
								layers[str(y as int)].queue_redraw()
					if not need_process:
						this.setpBW(ctx, &"need_process", false)
					for item in this.getp(&"layer").values():
						item.queue_redraw(),
		}),
		&"on_round": func (ctx: LisperContext, this: Mono, delta: float) -> void:
			var contains := this.getpB(&"contains") as Array
			for mono in contains:
				if mono.inited:
					await (mono as Mono).callc(ctx, &"on_round", delta),
		&"on_init": Prop.puts({
			&"0:chunk": func (ctx: LisperContext, this: Mono) -> void:
				var size := this.getp(&"chunk_size") as Vector2
				var cell := this.getp(&"chunk_cell") as Vector3
				var dcell := Vector2(cell.x, cell.y)
				this.setpB(&"pick_box", Rect2(-dcell / 2, dcell * size))
				var act_layer := this.getpBR(&"act_layer").duplicate() as Array
				act_layer.append_array(range(size.y).map(func (i): return str(i)))
				this.setpB(&"act_layer", act_layer),
		}),
		&"on_ready": Prop.puts({
			&"0:chunk": func (ctx: LisperContext, this: Mono) -> void:
				@warning_ignore("redundant_await")
				await Chunk.rebuild_mat(ctx, this),
		}),
		&"on_control_enter": Prop.puts({
			&"0:chunk": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
				Chunk.update_position(ctx, this)
				Chunk.update_control(ctx, this, ctrl),
			&"99:chunk_shadow": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
				var item := this.getpB(&"layer")[ctrl] as SekaiItem
				item.set_y(this.position.y + floorf(this.position.z + 2) * 64),
		}),
		&"on_control_exit": Prop.puts({
			&"0:chunk": Chunk.exit_control,
		}),
		&"on_store": Prop.puts({
			&"-1:chunk": func (ctx: LisperContext, this: Mono) -> void:
				this.setpB(&"contains", [])
				this.setpB(&"chunk_mat", null)
				pass,
		}),
		&"on_draw": Prop.puts({
			&"99:chunk": Chunk.draw_shadow,
		}),
		&"on_draw_debug": Prop.puts({
			&"99:chunk": Chunk.draw_debug,
		} if ProjectSettings.get_setting(&"sekai/debug_draw_chunk") else {}),
		&"on_position_mod": Prop.puts({
			&"0:chunk": Chunk.update_position,
		}),
		&"after_need_process": Prop.Stack({
			&"0:chunk": func (ctx: LisperContext, this: Mono, need: bool) -> void:
				this.setp(&"need_redraw", need),
		}),
	})
	return sets

static func draw_debug(ctx: LisperContext, this: Mono, ctrl: SekaiControl, item: SekaiItem) -> void:
	if this.getp(&"kami_select"):
		var offset := Vector2(this.position.x, this.position.y - this.position.z)
		#var data := this.getp(&"chunk_data") as Array
		var size := this.getp(&"chunk_size") as Vector2
		var cell := this.getp(&"chunk_cell") as Vector3
		var dcell := Vector2(cell.x, cell.y) * 0.9
		for x in size.x:
			for y in size.y:
				var pos := offset + Vector2(x * cell.x, y * cell.y)
				item.draw_rect(Rect2(pos - dcell/2, dcell), Color(1, 1, 1, 0.4), false)
				#var i := (y * size.x + x) as int
				#var rid = data[i % data.size()]
				#if rid != -1:
					#item.draw_rect(Rect2(pos - dcell/2, dcell), Color(1, 1, 1, 0.2), true)

const shadow := preload("res/shadow.png")

static func draw_shadow(ctx: LisperContext, this: Mono, ctrl: SekaiControl, item: SekaiItem) -> void:
	var contains := this.getp(&"contains") as Array
	for mono in contains:
		if not mono.inited or mono.define.ref == 2000:
			item.pen_draw_texture(shadow, Rect2(mono.position.x - 3, mono.position.y - 3, 6, 6))

static func rebuild_mat(ctx: LisperContext, this: Mono) -> void:
	var offset := this.position
	var data := this.getp(&"chunk_data") as Array
	var size := this.getp(&"chunk_size") as Vector2
	var cell := this.getp(&"chunk_cell") as Vector3
	var contains := []
	var mat := []
	mat.resize(size.y as int)
	for y in size.y:
		var line := []
		line.resize(size.x as int)
		for x in size.x:
			var i := (y * size.x + x) as int
			var rid = data[i % data.size()]
			if rid != -1:
				var mono := sekai.make_mono(rid)
				mono.position = Vector3(x, y, 0) * cell + offset
				mono.root = this
				contains.append(mono)
				line[x] = mono
			else:
				line[x] = null
		mat[y] = line
	this.setpB(&"contains", contains)
	this.setpB(&"chunk_mat", mat)
	#await Async.array_map(contains, func (mono): await mono._into_container(ctx, this))
	var layer_data := this.getp(&"layer_data") as Dictionary
	for ctrl in layer_data.keys():
		Chunk.update_control(ctx, this, ctrl)
	this.setpBW(ctx, &"need_process", true)

static func update_control(ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
	var mat := this.getp(&"chunk_mat") as Array
	var layers := this.getp(&"layer_data")[ctrl] as Dictionary
	for y in mat.size():
		var line := mat[y] as Array
		var lconts := line.filter(func (i): return i != null)
		var item := layers[str(y as int)] as SekaiItem
		for mono in lconts:
			var items := mono.getpBD(&"layer", {}) as Dictionary
			items[ctrl] = item
			mono.setpB(&"layer", items)
		for conn in item.on_draw.get_connections():
			item.on_draw.disconnect(conn[&"callable"])
		if lconts.size() > 0:
			item.on_draw.connect(func ():
				for mono in lconts:
					if mono.inited:
						mono.callf_on_draw(ctx, ctrl, item)
					else:
						var mpos := mono.position as Vector3
						var pos := Vector2(mpos.x, mpos.y - mpos.z)
						if ctrl._is_idle(pos):
							mono.init(ctx)
							mono.callf_on_draw(ctx, ctrl, item)
						else:
							ctrl._update_padding_pos(pos)
			)

static func exit_control(ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
	var contains := this.getp(&"contains") as Array
	for mono in contains:
		var items := mono.getpBD(&"layer", {}) as Dictionary
		items.erase(ctrl)
	var mat := this.getp(&"chunk_mat") as Array
	var layers := this.getp(&"layer_data")[ctrl] as Dictionary
	for y in mat.size():
		var item := layers[str(y as int)] as SekaiItem
		for conn in item.on_draw.get_connections():
			item.on_draw.disconnect(conn[&"callable"])

static func update_position(ctx: LisperContext, this: Mono) -> void:
	var offset := this.position
	var size := this.getp(&"chunk_size") as Vector2
	var cell := this.getp(&"chunk_cell") as Vector3
	var data := this.getp(&"layer_data") as Dictionary
	for y in size.y:
		var oy := offset.y + cell.y * y + floorf(offset.z) * 64.0
		for layers in data.values():
			var item := layers[str(y as int)] as SekaiItem
			item.set_y(oy)
