class_name TATile extends MonoTrait

var id := &"atile"
var requires := [&"compile", &"position"]

var props := {
	&"atile_size": Vector3(0, 0, 0),
	&"atile_matches": [],
	&"atile_rules": [],
	
	&"atile_cache": null,
	&"compilers": Prop.puts({
		&"0:atile": func (ctx: LisperContext, this: Mono) -> void:
			var atile_size := this.getp(&"atile_size") as Vector3
			if atile_size != Vector3(0, 0, 0):
				var atile_matches := this.getp(&"atile_matches") as Array
				var atile_data := this.getp(&"atile_rules") as Array
				var size := this.getp(&"size") as Vector3
				var rx := int((atile_size.x - 1) / 2)
				var ry := int((atile_size.y - 1) / 2)
				var rz := int((atile_size.z - 1) / 2)
				var sx := 1 + rx * 2
				var sy := 1 + ry * 2
				var sz := 1 + rz * 2
				var length := sx * sy * sz
				this.setpR(&"atile_cache", [
					atile_matches,
					atile_data,
					size,
					rx, ry, rz,
					sx, sy, sz,
					length,
				]),
	}),
	
	&"on_ready": Prop.puts({
		&"-9:atile": TATile.update,
	}),
}

static func update(ctx: LisperContext, this: Mono) -> void:
	var cache = this.getpR(&"atile_cache")
	if cache != null:
		var hako := this.get_hako()
		var pos := this.position
		var atile_matches := cache[0] as Array
		var atile_data := cache[1] as Array
		var size := cache[2] as Vector3
		var rx := cache[3] as int
		var ry := cache[4] as int
		var rz := cache[5] as int
		var sx := cache[6] as int
		var sy := cache[7] as int
		var sz := cache[8] as int
		var base := []
		base.resize(cache[9])
		for idx in base.size(): base[idx] = []
		for dz in sz:
			for dy in sy:
				for dx in sx:
					var monos = await hako.callm(ctx, &"collect_by_pos", pos + Vector3(dx - rx, dy - ry, dz - rz) * size)
					for idx in atile_matches.size():
						for mono in monos:
							if mono != this and await mono.callmRS(ctx, &"group_intersects", atile_matches[idx]):
								base[(sz - 1 - dz) * sy * sx + dy * sx + dx].append(idx + 1)
								break
		for rule in atile_data:
			var mask := rule[0] as Array
			var cfg := rule[1] as Dictionary
			var idx := 0
			var matched := true
			while idx < mask.size():
				var bit = int(mask[idx])
				if (bit > 0 and not base[idx].has(bit)) \
				or (bit < 0 and base[idx].has(-bit)):
					matched = false
					break
				idx += 1
			if matched:
				var cover = cfg.get(&"cover")
				if cover != null: this.cover(&"atile", cover)
				var vupdate = cfg.get(&"update")
				if vupdate != null: await ctx.call_method(this, vupdate)
				break
	pass
