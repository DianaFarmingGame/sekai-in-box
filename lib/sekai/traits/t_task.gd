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
	# 		"required": "",
	# 		"desc": "",
	#	}],
	&"task/define": func(ctx, this: Mono, task: Dictionary):
		this.setp("task_data", task)
		,

	&"task/set_status": func(ctx, this: Mono, status: TASK_STATUS):
		this.setpW(ctx, &"task_status", status)
		,

	#--------------------------------------------------------------------------#

	&"after_task_status": func(ctx, this: Mono, status: TASK_STATUS):
		if status == TASK_STATUS.Started:
			this.setp("processing", true)
		else:
			this.setp("processing", false)
		,

	&"add_watch_vars": func(ctx, this: Mono):
		this.puts(&"on_data_change_actions", {
			&"0:task": func(ctx, this: Mono, action: String, value):
				if action == "task_status":
					this.after_task_status(ctx, value)
				},)
		,

	&"remove_watch_vars": func(ctx, this: Mono):
		this.dels(&"on_data_change_actions", &"0:task")
		,

	&"on_process": Prop.puts({
		&"0:task_requirements_check": func(ctx, this: Mono):
			
			,
	}),
	
}

enum TASK_STATUS {
	NotStarted = 0,
	Started = 1,
	Completed = 2,
	Failed = 3,
}

enum TASK_TYPE {

}