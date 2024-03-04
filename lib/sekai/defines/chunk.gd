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
			var rid := sekai.get_define(ref_id).ref as int
			data[(pos.y * size.x + pos.x) as int] = rid
			var mono := sekai.make_mono(rid)
			mono.position = Vector3(pos.x, pos.y, 0) * cell + offset
			var mat := this.getp(&"chunk_mat") as Array
			var contains := this.getp(&"contains") as Array
			var prev = mat[pos.y][pos.x]
			mat[pos.y][pos.x] = mono
			if prev != null:
				contains.erase(prev)
				(prev as Mono)._outof_container()
			contains.append(mono)
			await mono._into_container(ctx, this)
			await this.get_hako().callmRSU(ctx, &"update_region", AABB(Vector3(pos.x, pos.y, 0) + this.position, Vector3()).grow(1))
			var layer_data := this.getp(&"layer_data") as Dictionary
			for ctrl in layer_data.keys():
				Chunk.update_control(ctx, this, ctrl)
			pass,
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
			pass,
		&"collect_by_pos": func (ctx: LisperContext, this: Mono, pos: Vector3) -> Mono:
			var offset := this.position
			var cell := this.getp(&"chunk_cell") as Vector3
			if abs(offset.z - pos.z) < cell.z / 2:
				var posi = Vector3i((pos - offset) / cell)
				var size := this.getp(&"chunk_size") as Vector2
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
					return null
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
		
		
		
		&"on_process": null,
		&"on_init": Prop.puts({
			&"0:chunk": func (ctx: LisperContext, this: Mono) -> void:
				var size := this.getp(&"chunk_size") as Vector2
				var cell := this.getp(&"chunk_cell") as Vector3
				var dcell := Vector2(cell.x, cell.y)
				this.setpB(&"pick_box", Rect2(-dcell / 2, dcell * size))
				var act_layer := this.getpR(&"act_layer") as Array
				act_layer.append_array(range(size.y).map(func (i): return str(i)))
				this.setpB(&"act_layer", act_layer),
		}),
		&"on_ready": Prop.puts({
			&"0:chunk": func (ctx: LisperContext, this: Mono) -> void:
				await Chunk.rebuild_mat(ctx, this),
		}),
		&"on_control_enter": Prop.puts({
			&"0:chunk": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
				Chunk.update_control(ctx, this, ctrl)
				Chunk.update_position(ctx, this),
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
		&"on_draw_debug": Prop.puts({
			&"99:chunk": Chunk.draw_debug,
		} if ProjectSettings.get_setting(&"sekai/debug_draw_chunk") else {}),
		&"on_position_mod": Prop.puts({
			&"0:chunk": Chunk.update_position,
		}),
	})
	return sets

static func draw_debug(ctx: LisperContext, this: Mono, ctrl: SekaiControl, item: SekaiItem) -> void:
	if this.getp(&"kami_select"):
		var offset := Vector2(this.position.x, this.position.y - this.position.z * item.ratio_yz)
		#var data := this.getp(&"chunk_data") as Array
		var size := this.getp(&"chunk_size") as Vector2
		var cell := this.getp(&"chunk_cell") as Vector3
		var dcell := Vector2(cell.x, cell.y) * 0.9
		for x in size.x:
			for y in size.y:
				var pos := offset + Vector2(x, y)
				item.draw_rect(Rect2(pos - dcell/2, dcell), Color(1, 1, 1, 0.4), false)
				#var i := (y * size.x + x) as int
				#var rid = data[i % data.size()]
				#if rid != -1:
					#item.draw_rect(Rect2(pos - dcell/2, dcell), Color(1, 1, 1, 0.2), true)

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
				contains.append(mono)
				line[x] = mono
			else:
				line[x] = null
		mat[y] = line
	this.setpB(&"contains", contains)
	this.setpB(&"chunk_mat", mat)
	await Async.array_map(contains, func (mono): await mono._into_container(ctx, this))
	var layer_data := this.getp(&"layer_data") as Dictionary
	for ctrl in layer_data.keys():
		Chunk.update_control(ctx, this, ctrl)

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
		item.on_draw.connect(func ():
			for mono in lconts:
				mono.applym(ctx, &"on_draw", [ctrl, item]))

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
		var oy := offset.y + cell.y * y + floorf(offset.z) * 64
		for layers in data.values():
			var item := layers[str(y as int)] as SekaiItem
			item.set_y(oy)
