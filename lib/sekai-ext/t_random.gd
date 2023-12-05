class_name TRandom extends MonoTrait

var id := &"random"

var props := {
	&"random_rules": [],
	&"random_cur": 0,
	&"on_init": Prop.puts({
		&"-99:random": TRandom.update,
		&"99:random": TRandom.updated,
	}),
	&"on_restore": Prop.puts({
		&"-99:random": TRandom.update,
		&"99:random": TRandom.updated,
	}),
}

static func update(_sekai, this: Mono) -> void:
	this = this.upgrade()
	var random_rules := this.getp(&"random_rules") as Array
	if random_rules.size() > 0:
		var wtotal := 0.0
		for rule in random_rules:
			wtotal += rule[0]
		var rd := randf() * wtotal
		for idx in random_rules.size():
			var rule = random_rules[idx]
			rd -= rule[0]
			if rd <= 0:
				this.setp(&"random_cur", idx)
				var cover = rule[1].get(&"cover")
				if cover != null: this.cover(&"random", cover)
				var vupdate = rule[1].get(&"update")
				if vupdate != null: update.call(_sekai, this)
				break
	pass

static func updated(_sekai, this: Mono) -> void:
	var random_rules := this.getp(&"random_rules") as Array
	if random_rules.size() > 0:
		var cur = this.getp(&"random_cur")
		var rule = random_rules[cur]
		var vupdated = rule[1].get(&"updated")
		if vupdated != null: updated.call(_sekai, this)
	pass
