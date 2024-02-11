class_name TDatabase extends MonoTrait

var id := &"database"

var props := {
	&"data": {},
	&"group_info": {},

	&"db/set": func(ctx: LisperContext, this: Mono, key: StringName, value, group: StringName = &"default") -> void:
		var db = this.getp("data") as Dictionary
		if !db.has(group):
			db[group] =  {}
			print("db/set: ", "create database group: ", group)
		db[group][key] = value
		,

	&"db/get": func(ctx: LisperContext, this: Mono, group: StringName, key: StringName) -> Variant:
		var db = this.getp("data") as Dictionary
		if db.has(group) and db[group].has(key):
			return db[group][key]
		
		push_error("db/get: ", group, " : ", key, " not exist")
		return null
		,

	&"db/getp": func(ctx: LisperContext, this: Mono, key: StringName, props_: StringName, group: StringName = &"default") -> Variant:
		var db = this.getp("data") as Dictionary
		if db.has(group) and db[group].has(key):
			var data = db[group][key]
			if !(data is Dictionary):
				push_error("db/getp: ", group, " : ", key ," is not Dictionary")
				return null
			
			if data.has(props_):
				return data[props_]

			push_error("db/getp: ", group, " : ", key, " : ", props_ ," not exist")
		else:
			push_error("db/getp: ", group, " : ", key, " not exist")

		return null
		,

	&"db/setp": func(ctx: LisperContext, this: Mono, key: StringName, props_: StringName, value, group: StringName = &"default"):
		var db = this.getp("data") as Dictionary
		if db.has(group) and db[group].has(key):
			var data = db[group][key]
			if !(data is Dictionary):
				push_error("db/setp: ", group, " : ", key ," is not Dictionary")
				return
			
			data[props_] = value
		else:
			push_warning("db/setp: ", group, " : ", key, " not exist")
			this.applym(ctx, &"db/set", [key, value, {props_: value}])
		,

	&"db/set_group_info": func(ctx: LisperContext, this: Mono, group: StringName, mapping: Dictionary):
		var gi = this.getp("group_info")
		if gi.has(group):
			push_warning(&"db/set_group_info: ", "define existing group_info ", group)
		gi[group] = mapping
		,

	&"db/get_group_info": func(ctx: LisperContext, this: Mono, group: StringName, mapping: Dictionary) -> Dictionary:
		var gi = this.getp("group_info")
		if !gi.has(group) || group == &"default":
			push_warning("db/get_group_info: ", "missing group_info ", group)
			return {}
		return gi[group]
}
