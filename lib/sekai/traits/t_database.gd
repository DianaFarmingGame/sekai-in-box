class_name TDatabase extends MonoTrait

var id := &"database"

var props := {
	&"data": {},

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
}
