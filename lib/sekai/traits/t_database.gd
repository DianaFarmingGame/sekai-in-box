class_name TDatabase extends MonoTrait

var id := &"database"

var props := {
	&"data": {},
	&"group_info": {},

	&"db/set": func(ctx: LisperContext, this: Mono, key: StringName, value, group: StringName = &"default") -> void:
		var db = this.getp("data") as Dictionary
		db[group] = db[group] if db.has(group) else {}
		db[group][key] = value
		,

	&"db/get": func(ctx: LisperContext, this: Mono, group: StringName, key: StringName) -> Variant:
		var db = this.getp("data") as Dictionary
		if db.has(group) and db[group].has(key):
			return db[group][key]
		else:
			return null
		,

	&"db/getp": func(ctx: LisperContext, this: Mono, key: StringName, props_: StringName, group: StringName = &"default") -> Variant:
		var db = this.getp("data") as Dictionary
		if db.has(group) and db[group].has(key):
			var data = db[group][key]
			assert(data is Dictionary)
			return data[props_] if data.has(props_) else null
		else:
			return null
		,

	&"db/setp": func(ctx: LisperContext, this: Mono, key: StringName, props_: StringName, value, group: StringName = &"default") -> void:
		var db = this.getp("data") as Dictionary
		if db.has(group) and db[group].has(key):
			var data = db[group][key]
			assert(data is Dictionary)
			data[props_] = value
		else:
			db[group] = db[group] if db.has(group) else {}
			db[group][key] = {props_: value}
		,

	&"db/set_group_info": func(ctx: LisperContext, this: Mono, group: StringName, mapping: Dictionary):
		var gi = this.getp("group_info")
		if gi.has(group):
			print("Repeat define group_info ", group)
		gi[group] = mapping
		,

	&"db/get_group_info": func(ctx: LisperContext, this: Mono, group: StringName, mapping: Dictionary) -> Dictionary:
		var gi = this.getp("group_info")
		if !gi.has(group):
			print("missing group_info ", group)
			return {}
		return gi[group]
}
