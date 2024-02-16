class_name TTask extends MonoTrait

var id := &"task"

var requires := [&"process"]

# &"is_ok_task_" + id + "_" + idx
# &"is_ok_task_" + id + "_all"

var props := {
	&"task_data": {},
	&"task_status": TASK_STATUS.NOT_START,

	# task format
	# {
	# 	"id": &"",
	# 	"group": &"",
	# 	"name": "",
	# 	"desc": "",
	# 	"next": &"",
	# 	"finish": &"",
	# 	"status": TASK_STATUS,
	# 	"requirements: [{
	# 		"type": TASK_TYPE,
	# 		"data": {
	#			"key": "",
	#			"value": "",
	#			"compare": COMPAIR_TYPE,
	#		},
	#		"current": ""
	# 		"desc": "",
	#       "complete": bool
	#	}],

	&"task/start": func(ctx, this: Mono):
		print("task " + this.getp(&"task_data")["id"] + " start")
		this.callm(ctx, &"task/set_status", TASK_STATUS.START)
		,

	&"task/complete": func(ctx, this: Mono):
		print("task " + this.getp(&"task_data")["id"] + " complete")
		this.callm(ctx, &"task/set_status", TASK_STATUS.COMPLETE)
		,

	#--------------------------------------------------------------------------#
	&"task/set_status": func(ctx, this: Mono, status: TASK_STATUS):
		var cur_status = this.getp(&"task_status")
		if status == cur_status:
			push_warning("[task/start] task " + this.getp("task_data")["id"] + " already in ", status)
			return
		this.setpW(ctx, &"task_status", status)
		,

	&"after_task_status": func(ctx, this: Mono, status: TASK_STATUS):
		watch_init(ctx, this, status)
		,

	&"task/add_watch_vals": func(ctx, this: Mono):
		sekai.gikou.pushs(&"on_data_change_vals", [
			&"0:task_" + this.getp(&"task_data")["id"], func(ctx, gikou: Mono, key: String, value):
					if key.begins_with("is_ok_task_"):
						return
					var require = this.getp(&"task_data")["requirements"] as Array
					for i in len(require):
						var r = require[i]
						if r["type"] == REQUIREMENT_TYPE.WATCH_VAR and r["data"]["key"] == key:
							r["current"] = value
							check_vals(ctx, this, gikou, r, i)

					check_all_requirements(ctx, this, gikou, require)
					,
				],)
		,

	&"task/remove_watch_vals": func(ctx, this: Mono):
		sekai.gikou.dels(&"on_data_change_vals", &"0:task_" + this.getp(&"task_data")["id"])
		,

	&"task/add_container_watch": func(ctx, this: Mono):
		var mono_id_map = {}
		for r_ in this.getp(&"task_data")["requirements"]:
			var mono_id = r_["data"]["mono_id"]
			if mono_id_map.has(mono_id):
				continue
			#TODO switch to global mono get
			var hako = await sekai.gikou.emitm(ctx, &"get_hako")
			var mono = await hako.callm(ctx, &"container/get_by_ref_id", mono_id) as Mono
			mono_id_map[mono_id] = true
			mono.pushs(&"on_contains_mod", [
				&"0:task_" + this.getp(&"task_data")["id"], func(ctx, mono: Mono):
						var require = this.getp(&"task_data")["requirements"] as Array
						var gikou = sekai.gikou
						for i in len(require):
							var r = require[i]
							if r["type"] == REQUIREMENT_TYPE.BAG_CHECK:
								r["current"] = mono.callmRSUY(ctx, &"container/count_by_ref_id", r["data"]["key"])
								check_vals(ctx, this, gikou, r, i)

						check_all_requirements(ctx, this, gikou, require)
						,
					],)
		,

	&"task/remove_container_watch": func(ctx, this: Mono):
		sekai.gikou.dels(&"on_contains_mod", &"0:task_" + this.getp(&"task_data")["id"])
		,

	&"task/add_task_watcher": func(ctx, this: Mono):
		sekai.gikou.pushs(&"on_data_change_vals", [
			&"1:task_" + this.getp(&"task_data")["id"], func(ctx, gikou: Mono, key: StringName, value):
					if key == this.getp("task_data")["finish"] && value == true:
						this.emitm(ctx, &"task/complete")
					,
				],)
		,

	&"task/remove_task_watcher": func(ctx, this: Mono):
		sekai.gikou.dels(&"on_data_change_vals", &"1:task_" + this.getp(&"task_data")["id"])
		,
		

	&"on_process": Prop.puts({
		&"0:task_requirements_check": func(ctx, this: Mono):
			pass
			,
	}),

	&"on_ready": Prop.puts({
		&"0:task_requirements_check": func(ctx, this: Mono):
			var status = this.getp(&"task_status")
			watch_init(ctx, this, status)
					
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
	BAG_CHECK = 1,
	DISTANCE_CHECK = 2,
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
	if a is bool:
		b = false if b == 0 else true
		
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

func finish_requirement_db(ctx: LisperContext, id: StringName, name: String, gikou: Mono):
	gikou.applym(ctx, "db/set", ["is_ok_task_" + id + "_" + name, true, &"vals"])

func unfinish_requirement_db(ctx: LisperContext, id: StringName, name: String, gikou: Mono):
	gikou.applym(ctx, "db/set", ["is_ok_task_" + id + "_" + name, false, &"vals"])

func watch_init(ctx: LisperContext, this: Mono, status: TASK_STATUS):
	if status == TASK_STATUS.START:
		this.setp(&"processing", true)
		var task = this.getp(&"task_data")
		
		if task["finish"] != &"":
			this.emitm(ctx, &"task/add_task_watcher")
			
		data_init(ctx, this)
		
		var flags = []
		for i in len(REQUIREMENT_TYPE):
			flags.append(false)

		for r in task["requirements"]:
			if r["type"] == REQUIREMENT_TYPE.WATCH_VAR:
				flags[REQUIREMENT_TYPE.WATCH_VAR] = true
			elif r["type"] == REQUIREMENT_TYPE.BAG_CHECK:
				flags[REQUIREMENT_TYPE.BAG_CHECK] = true
			elif r["type"] == REQUIREMENT_TYPE.DISTANCE_CHECK:
				flags[REQUIREMENT_TYPE.DISTANCE_CHECK] = true

		if flags[REQUIREMENT_TYPE.WATCH_VAR]:
			this.emitm(ctx, &"task/add_watch_vals")
		if flags[REQUIREMENT_TYPE.BAG_CHECK]:
			this.emitm(ctx, &"task/add_container_watch")
	else:
		this.setp(&"processing", false)
		this.emitm(ctx, &"task/remove_watch_vals")
		this.emitm(ctx, &"task/remove_task_watcher")


func check_vals(ctx, this: Mono, gikou: Mono, r, idx):
	var res := var_compare(r["current"], r["data"]["value"], r["data"]["compare"])
	if res:
		r["complete"] = true
		print("task " + this.getp(&"task_data")["id"] + " requirement ", idx , " complete")
		finish_requirement_db(ctx, this.getp(&"task_data")["id"], str(idx), gikou)
	else:
		r["complete"] = false
		unfinish_requirement_db(ctx, this.getp(&"task_data")["id"], str(idx), gikou)

func check_all_requirements(ctx, this: Mono, gikou: Mono, require):
	var flag = true
	for r in require:
		if r["complete"] == false:
			flag = false
			break
		
	if flag:
		print("task " + this.getp(&"task_data")["id"] + " all requirement complete")
		finish_requirement_db(ctx, this.getp(&"task_data")["id"], "all", gikou)

func data_init(ctx: LisperContext, this: Mono):
	var require = this.getp(&"task_data")["requirements"] as Array
	await sekai.gikou.applym(ctx, "db/set", [&"is_ok_task_" + this.getp(&"task_data")["id"] + "_all", false, &"vals"])
	for i in len(require):
		var r = require[i]
		r["complete"] = false

		await sekai.gikou.applym(ctx, "db/set", [&"is_ok_task_" + this.getp(&"task_data")["id"] + "_" + str(i), false, &"vals"])

		if r["type"] == REQUIREMENT_TYPE.WATCH_VAR:
			r["current"] = sekai.gikou.applymRSUY(ctx, "db/get", [r["data"]["key"], &"vals"])
		elif r["type"] == REQUIREMENT_TYPE.BAG_CHECK:
			r["current"] = sekai.gikou.callmRSUY(ctx, &"container/count_by_ref_id", r["data"]["key"])
		elif r["type"] == REQUIREMENT_TYPE.DISTANCE_CHECK:
			pass

		check_vals(ctx, this, sekai.gikou, r, i)
			
	check_all_requirements(ctx, this, sekai.gikou, require)
