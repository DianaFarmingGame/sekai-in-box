class_name TATile extends MonoTrait

var id := &"atile"
var requires := [&"group", &"position"]

var props := {
	&"atile_size": Vector3(1, 1, 1),
	&"atile_matches": [],
	&"atile_rules": [],
	&"on_init": Prop.puts({
		&"-9:atile": TATile.update,
	}),
	&"on_restore": Prop.puts({
		&"-9:atile": TATile.update,
	}),
}

static func update(sekai: Sekai, this: Mono) -> void:
	this = this.upgrade()
	var pos := this.position
	var size := this.getp(&"size") as Vector3
	var atile_size := this.getp(&"atile_size") as Vector3
	var atile_matches := this.getp(&"atile_matches") as Array
	var atile_data := this.getp(&"atile_rules") as Array
	var rx := int((atile_size.x - 1) / 2)
	var ry := int((atile_size.y - 1) / 2)
	var rz := int((atile_size.z - 1) / 2)
	var sx := 1 + rx * 2
	var sy := 1 + ry * 2
	var sz := 1 + rz * 2
	var base := []
	base.resize(sx * sy * sz)
	for idx in base.size(): base[idx] = []
	for dz in sz:
		for dy in sy:
			for dx in sx:
				var monos := sekai.get_monos_by_pos(pos + Vector3(dx - rx, dy - ry, dz - rz) * size)
				for idx in atile_matches.size():
					for mono in monos:
						if mono != this and mono.callm(&"group_intersects", atile_matches[idx]):
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
			if vupdate != null: sekai.gss_ctx.call_anyway_async(vupdate, [sekai, this])
			break
	pass
