class_name TRTile extends MonoTrait

var id := &"rtile"

var props := {
	&"rtile_rules": [],
	&"on_init": Prop.puts({
		&"-99:rtile": TRTile.update,
	}),
	&"on_restore": Prop.puts({
		&"-99:rtile": TRTile.update,
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
		for rule in rtile_rules:
			rd -= rule[0]
			if rd <= 0:
				var cover = rule[1].get(&"cover")
				if cover != null: this.cover(&"rtile", cover)
				break
	pass
