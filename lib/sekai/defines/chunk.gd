class_name Chunk extends Box

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "Chunk"
	ref = 100
	id = &"chunk"
	merge_traits(sets, [TPosition])
	merge_props(sets, {
		&"chunk_size": Vector2(0, 0),
		&"chunk_cell": Vector3(1, 1, 1),
		&"chunk_data": [-1],
		
		&"chunk_mat": null,
		&"chunk_items": [],
		
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
		
		
		
		&"on_process": null,
		&"on_control_enter": Prop.puts({
			&"0:chunk": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
				var offset := this.position
				var data := this.getp(&"chunk_data") as Array
				var size := this.getp(&"chunk_size") as Vector2
				var cell := this.getp(&"chunk_cell") as Vector3
				var contains := []
				var mat := []
				mat.resize(size.y as int)
				var items := []
				items.resize(size.y as int)
				for y in size.y:
					var line := []
					var lconts := []
					line.resize(size.x as int)
					var item := SekaiItem.new()
					item.on_draw.connect(func ():
						for mono in lconts:
							mono.callmR(ctx, &"on_draw", item)
					)
					item.set_y(offset.y + cell.y * y + floorf(offset.z) * 64)
					for x in size.x:
						var i := (y * size.x + x) as int
						var rid = data[i % data.size()]
						if rid != -1:
							var mono := sekai.make_mono(rid)
							mono.position = Vector3(x, y, 0) * cell + offset
							mono.setpB(&"sekai_item", item)
							contains.append(mono)
							lconts.append(mono)
							line[x] = mono
						else:
							line[x] = null
					mat[y] = line
					items[y] = item
					ctrl.add_child(item)
				this.setpB(&"contains", contains)
				this.setpB(&"chunk_mat", mat)
				this.setpB(&"chunk_items", items)
				await Async.array_map(contains, func (item): await item._into_container(ctx, this))
				pass,
		}),
		&"on_control_exit": Prop.puts({
			&"0:chunk": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
				var items := this.getp(&"chunk_items") as Array
				for item in items:
					ctrl.remove_child(item)
					item.free()
				pass,
		}),
		&"on_store": Prop.puts({
			&"-1:chunk": func (ctx: LisperContext, this: Mono) -> void:
				this.setpB(&"contains", [])
				pass,
		}),
	})
	return sets
