class_name TDatabase extends MonoTrait

var id := &"database"

var props := {
	&"data": {},
	&"group_info": {},
	&"watcher": {},

	&"db/set": func(ctx: LisperContext, this: Mono, key: StringName, value, group: StringName = &"default") -> void:
		var db = this.getp("data") as Dictionary
		if !db.has(group):
			db[group] =  {}
			print("db/set: ", "create database group: ", group)
		db[group][key] = value

		if this.getp("watcher").has(group):
			this.callm(ctx, &"on_data_change_" + group, [key, value])
		,

	&"db/setgw": func(ctx: LisperContext, this: Mono, group: StringName = &"default") -> void:
		var db = this.getp("data") as Dictionary
		var watcher = this.getp("watcher") as Dictionary

		if !db.has(group):
			db[group] =  {}
			print("db/setgw: ", "create database group: ", group)

		print("db/setgw: ", "add group watch: ", group)
		watcher[group] = true
		this.setp(&"on_data_change_" + group, {})
		,

	&"db/get": func(ctx: LisperContext, this: Mono, group: StringName, key: StringName) -> Variant:
		var db = this.getp("data") as Dictionary
		if db.has(group) and db[group].has(key):
			return db[group][key]
		
		push_error("db/get: ", group, " : ", key, " not exist")
		return null
		,

	&"db/getg": func(ctx: LisperContext, this: Mono, key: StringName, group: StringName = &"default") -> Variant:
		var db = this.getp("data") as Dictionary
		if db.has(group) and db[group].has(key):
			return db[group][key]
		
		push_error("db/getg: ", group, " : ", key, " not exist")
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
		,
		
	
	&"on_ready": Prop.puts({
		&"-99:database": func (ctx: LisperContext, this: Mono) -> void:
			var watcher = this.getp("watcher") as Dictionary
			for group in watcher:
				this.setp(&"on_data_change_" + group, Prop.Stack())
			,
	}),
}
