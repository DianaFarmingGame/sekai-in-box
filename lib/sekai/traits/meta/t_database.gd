class_name TDatabase extends MonoTrait

var id := &"database"

var props := {
	&"data": {},
	&"group_info": {},
	&"watcher": {},

	&"db/set": func(ctx: LisperContext, this: Mono, key: Variant, value, group: StringName = &"default") -> void:
		var db = this.getp(&"data") as Dictionary
		if !db.has(group):
			db[group] =  {}
			print("[db/set] ", "create database group: ", group)
		
		if db[group].has(key) and db[group][key] == value:
			return
		
		db[group][key] = value

		if this.getp("watcher").has(group):
			this.applym(ctx, &"on_data_change_" + group, [key, value])
		,

	&"db/setgw": func(ctx: LisperContext, this: Mono, group: StringName = &"default") -> void:
		var db = this.getp(&"data") as Dictionary
		var watcher = this.getp("watcher") as Dictionary

		if !db.has(group):
			db[group] =  {}
			print("[db/setgw] ", "create database group: ", group)

		print("[db/setgw] ", "add group watch: ", group)
		watcher[group] = true
		this.setp(&"on_data_change_" + group, Prop.Stack())
		,
		
	&"db/setp": func(ctx: LisperContext, this: Mono, key: StringName, props_: StringName, value, group: StringName = &"default"):
		var db = this.getp(&"data") as Dictionary
		if db.has(group) and db[group].has(key):
			var data = db[group][key]
			if !(data is Dictionary):
				push_error("[db/setp] ", group, " : ", key ," is not Dictionary")
				return
			
			data[props_] = value
		else:
			push_warning("[db/setp] ", group, " :", key, " not exist")
			this.applym(ctx, &"db/set", [key, {props_: value}])
		,

	&"db/getg": func(ctx: LisperContext, this: Mono, group: StringName = &"default") -> Variant:
		var db = this.getp(&"data") as Dictionary
		if db.has(group):
			return db[group]
	
		push_error("[db/getg] ", group, " not exist")
		return null
		,

	&"db/get": func(ctx: LisperContext, this: Mono, key: Variant, group: StringName = &"default") -> Variant:
		var db = this.getp(&"data") as Dictionary
		if db.has(group) and db[group].has(key):
			return db[group][key]
		
		push_error("[db/get] ", group, ": ", key, " not exist")
		return null
		,

	&"db/getp": func(ctx: LisperContext, this: Mono, key: StringName, props_: StringName, group: StringName = &"default") -> Variant:
		var db = this.getp(&"data") as Dictionary
		if db.has(group) and db[group].has(key):
			var data = db[group][key]
			if !(data is Dictionary):
				push_error("[db/getp] ", group, ": ", key ," is not Dictionary")
				return null
			
			if data.has(props_):
				return data[props_]

			push_error("[db/getp] ", group, ": ", key, " : ", props_ ," not exist")
		else:
			push_error("[db/getp] ", group, ": ", key, " not exist")

		return null
		,

	&"db/del": func(ctx: LisperContext, this: Mono, key: StringName, group: StringName = &"default"):
		var db = this.getp(&"data") as Dictionary
		if db.has(group) and db[group].has(key):
			db[group].erase(key)
		else:
			push_warning("[db/del] ", group, ": ", key, " not exist")
		,

	&"db/clean": func(ctx: LisperContext, this: Mono, key: StringName, group: StringName = &"default"):
		var db = this.getp(&"data") as Dictionary
		if db.has(group) and db[group].has(key):
			db[group][key] = {}
			print("[db/clean]: clean ", group, ": ", key)
		else:
			push_warning("[db/clean] ", group, ": ", key, " not exist")
		,

	&"db/has": func(ctx: LisperContext, this: Mono, key: StringName, group: StringName = &"default") -> bool:
		var db = this.getp(&"data") as Dictionary
		return db.has(group) and db[group].has(key)
		,

	&"db/set_group_info": func(ctx: LisperContext, this: Mono, group: StringName, mapping: Dictionary):
		var gi = this.getp(&"group_info")
		if gi.has(group):
			push_warning(&"[db/set_group_info] ", "define existing group_info ", group)
		gi[group] = mapping
		,

	&"db/get_group_info": func(ctx: LisperContext, this: Mono, group: StringName, mapping: Dictionary) -> Dictionary:
		var gi = this.getp(&"group_info")
		if !gi.has(group) || group == &"default":
			push_warning("[db/get_group_info] ", "missing group_info ", group)
			return {}
		return gi[group]
		,

	&"db/val_replace": func(ctx: LisperContext, this: Mono, data: Variant) -> Variant:
		return await db_val_replace(ctx, this, data)
		,
	
	&"on_ready": Prop.puts({
		&"-99:database": func (ctx: LisperContext, this: Mono) -> void:
			var watcher = this.getp("watcher") as Dictionary
			for group in watcher:
				this.setp(&"on_data_change_" + group, Prop.Stack())
			,
	}),
}

func db_val_replace(ctx: LisperContext, this: Mono, data: Variant) -> Variant:
	var entry = data
	var res := []
	if 	entry[0] == Lisper.TType.ARRAY or \
		entry[0] == Lisper.TType.MAP or	\
		entry[0] == Lisper.TType.LIST:
		for i in range(entry[1].size()):
			var r = await db_val_replace(ctx, this, entry[1][i])
			if r == null: 
				return null
			entry[1][i] = r
			
		res = entry
	elif entry[0] == Lisper.TType.TOKEN:
		if ctx.get_var(entry[1]) != null:
			res = entry
			return res
		var key = entry[1]
		var value = await this.applym(ctx, &"db/get", [key, &"vals"])
		assert(value != null, "data not found: " + key)
		
		if value is float:
			res = Lisper.Number(value)
		elif value is bool:
			res = Lisper.Bool(value)
		elif value is String:
			res = Lisper.String(value)
		elif value is Array:
			res = Lisper.List(value)
		
	else:
		res = entry

	return res
