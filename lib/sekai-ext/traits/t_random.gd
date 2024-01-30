class_name TRandom extends MonoTrait

var id := &"random"
var requires := [&"compile"]

var props := {
	&"random_rules": Prop.Stack([]),
	&"random_cur": 0,
	
	&"random_cache": null,
	&"compilers": Prop.puts({
		&"0:random": func (this: Mono) -> void:
			var random_rules := this.getp(&"random_rules") as Array
			if random_rules.size() > 0:
				var wtotal := 0.0
				for rule in random_rules:
					wtotal += rule[0]
				this.setpR(&"random_cache", [random_rules, wtotal]),
	}),
	
	&"on_init": Prop.puts({
		&"-99:random": TRandom.update,
		&"98:random": TRandom.updated,
	}),
	&"on_restore": Prop.puts({
		&"-99:random": TRandom.update,
		&"99:random": TRandom.updated,
	}),
}

static func update(this: Mono) -> void:
	var cache = this.getpR(&"random_cache")
	if cache != null:
		var rules := cache[0] as Array
		var total := cache[1] as float
		var rd := randf() * total
		for idx in rules.size():
			var rule = rules[idx]
			rd -= rule[0]
			if rd <= 0:
				this.setpBD(&"random_cache", rule)
				var cover = rule[1].get(&"cover")
				if cover != null: this.cover(&"random", cover)
				var vupdate = rule[1].get(&"update")
				if vupdate != null: await sekai.gss_ctx.call_fn(vupdate, [sekai, this])
				break
	pass

static func updated(this: Mono) -> void:
	var rule = this.getpB(&"random_cache")
	if rule != null:
		var vupdated = rule[1].get(&"updated")
		if vupdated != null: await sekai.gss_ctx.call_fn(vupdated, [sekai, this])
	pass
