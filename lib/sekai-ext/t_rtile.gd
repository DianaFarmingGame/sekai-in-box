class_name TRTile extends MonoTrait

var id := &"rtile"

var props := {
	&"rtile_rules": [],
	&"rtile_cur": 0,
	&"on_init": Prop.puts({
		&"-99:rtile": TRTile.update,
		&"99:rtile": TRTile.updated,
	}),
	&"on_restore": Prop.puts({
		&"-99:rtile": TRTile.update,
		&"99:rtile": TRTile.updated,
	}),
}

static func update(_sekai, this: Mono) -> void:
	this = this.upgrade()
	var rtile_rules := this.getp(&"rtile_rules") as Array
	if rtile_rules.size() > 0:
		var wtotal := 0.0
		for rule in rtile_rules:
			wtotal += rule[0]
		var rd := randf() * wtotal
		for idx in rtile_rules.size():
			var rule = rtile_rules[idx]
			rd -= rule[0]
			if rd <= 0:
				this.setp(&"rtile_cur", idx)
				var cover = rule[1].get(&"cover")
				if cover != null: this.cover(&"rtile", cover)
				var vupdate = rule[1].get(&"update")
				if vupdate != null: update.call(_sekai, this)
				break
	pass

static func updated(_sekai, this: Mono) -> void:
	var rtile_rules := this.getp(&"rtile_rules") as Array
	if rtile_rules.size() > 0:
		var cur = this.getp(&"rtile_cur")
		var rule = rtile_rules[cur]
		var vupdated = rule[1].get(&"updated")
		if vupdated != null: updated.call(_sekai, this)
	pass
