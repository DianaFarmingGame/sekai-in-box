class_name TTask extends MonoTrait

var id := &"task"

var requires := [&"process", &"database"]

var props := {
	&"task_data": {},
	&"task_status": 0,

	# task format
	# {
	# 	"id": &"",
	# 	"group": &"",
	# 	"name": "",
	# 	"desc": "",
	# 	"next": &"",
	# 	"finish": &"",
	# 	"requirements: [{
	# 		"type": TASK_TYPE,
	# 		"required": {
	#			"key": "",
	#			"value": "",
	#			"compare": COMPAIR_TYPE,
	#		},
	# 		"desc": "",
	#       "complete": bool
	#	}],
	&"task/define": func(ctx, this: Mono, task: Dictionary):
		for k in task["requirements"]:
			k["current"] = 0
			k["complete"] = false

		task["status"] = TASK_STATUS.NOT_START
			
		this.setp("task_data", task)
		,

	&"task/set_status": func(ctx, this: Mono, status: TASK_STATUS):
		this.setpW(ctx, &"task_status", status)
		,

	#--------------------------------------------------------------------------#

	&"after_task_status": func(ctx, this: Mono, status: TASK_STATUS):
		if status == TASK_STATUS.START:
			this.setp(&"processing", true)
		else:
			this.setp(&"processing", false)
		,

	&"add_watch_vars": func(ctx, this: Mono):
		sekai.gikou.puts(&"on_data_change_actions", {
			&"0:task" + this.getp(&"task_data")["id"]: func(ctx, gikou: Mono, key: String, value):
					var require = this.getp(&"task_data")["requirements"] as Array
					for i in len(require):
						var r = require[i]
						if r["type"] == REQUIREMENT_TYPE.WATCH_VAR and r["required"]["key"] == key:
							r.type.current = value
							var res := var_compare(r["required"]["value"], r["current"], r["required"]["compare"])
							if res:
								# finish_requirement_db(ctx, this.getp(&"task_data")["id"], i, gikou)
								r["complete"] = true
							else:
								# unfinish_requirement_db(ctx, this.getp(&"task_data")["id"], i, gikou)
								r["complete"] = false

					var flag = true
					for r in require:
						if r["complete"] == false:
							flag = false
							break

					if flag:
						finish_requirement_db(ctx, this.getp(&"task_data")["id"], "all", gikou)
					,
				},)
		,

	&"remove_watch_vars": func(ctx, this: Mono):
		sekai.gikou.dels(&"on_data_change_actions", &"0:task" + this.getp(&"task_data")["id"])
		,

	&"add_task_watcher": func(ctx, this: Mono):
		sekai.gikou.puts(&"on_data_change_actions", {
			&"1:task" + this.getp(&"task_data")["id"]: func(ctx, gikou: Mono, key: StringName, value):
					if key == this.getp("task_data")["finish"] && value == true:
						this.callm(ctx, &"task_status", TASK_STATUS.COMPLETE)
					,
				},)
		,

	&"on_process": Prop.puts({
		&"0:task_requirements_check": func(ctx, this: Mono):
			pass
			,
	}),
	
}

enum TASK_STATUS {
	NOT_START = 0,
	START = 1,
	COMPLETE = 2,
	FAIL = 3,
}

enum REQUIREMENT_TYPE {
	WATCH_VAR = 0,
}

enum COMPAIR_TYPE {
	EQUAL = 0,
	NOT_EQUAL = 1,
	GREATER = 2,
	LESS = 3,
	GREATER_EQUAL = 4,
	LESS_EQUAL = 5,
}

func var_compare(a, b, compare: COMPAIR_TYPE) -> bool:
	if compare == COMPAIR_TYPE.EQUAL:
		return a == b
	elif compare == COMPAIR_TYPE.NOT_EQUAL:
		return a != b
	elif compare == COMPAIR_TYPE.GREATER:
		return a > b
	elif compare == COMPAIR_TYPE.LESS:
		return a < b
	elif compare == COMPAIR_TYPE.GREATER_EQUAL:
		return a >= b
	elif compare == COMPAIR_TYPE.LESS_EQUAL:
		return a <= b
	else:
		return false

func finish_requirement_db(ctx: LisperContext, id: StringName, name: Variant, gikou: Mono):
	gikou.applym(ctx, "db/set", [&"is_ok_task_" + id + "_" + name, true])

func unfinish_requirement_db(ctx: LisperContext, id: StringName, name: Variant, gikou: Mono):
	gikou.applym(ctx, "db/set", [&"is_ok_task_" + id + "_" + name, false])