class_name TATile extends MonoTrait

var id := &"atile"

var props := {
	&"atile_size": Vector3(1, 1, 1),
	&"atile_group": null,
	&"atile_allow": [],
	&"atile_data": [],
	&"on_init": Prop.puts({
		&"-9:atile": TATile.update_atile,
	}),
	&"on_restore": Prop.puts({
		&"-9:atile": TATile.update_atile,
	}),
}

static func update_atile(sekai: Sekai, this: Mono) -> void:
	this = this.upgrade()
	var pos := this.position
	var atile_size := this.getp(&"atile_size") as Vector3
	var atile_allow := this.getp(&"atile_allow") as Array
	var atile_data := this.getp(&"atile_data") as Array
	var rx := int((atile_size.x - 1) / 2)
	var ry := int((atile_size.y - 1) / 2)
	var rz := int((atile_size.z - 1) / 2)
	var sx := 1 + rx * 2
	var sy := 1 + ry * 2
	var sz := 1 + rz * 2
	var base := []
	base.resize(sx * sy * sz)
	base.fill(false)
	for dz in sz:
		for dy in sy:
			for dx in sx:
				var monos := sekai.get_monos_by_pos(pos + Vector3(dx - rx, dy - ry, dz - rz))
				for mono in monos:
					if mono != this:
						var group = mono.getp(&"atile_group")
						if atile_allow.has(group):
							base[(sz - 1 - dz) * sy * sx + dy * sx + dx] = true
							break
	for rule in atile_data:
		var mask := rule[0] as Array
		var cfg := rule[1] as Dictionary
		var idx := 0
		var matched := true
		while idx < mask.size():
			match mask[idx]:
				-1.0:
					if base[idx] != false:
						matched = false
						break
				0.0:
					pass
				1.0:
					if base[idx] != true:
						matched = false
						break
				_:
					push_error("unknown atile match enum: ", mask[idx])
					matched = false
					break
			idx += 1
		if matched:
			var cover = cfg.get(&"cover")
			if cover != null: this.cover(&"atile", cover)
			break
	pass
