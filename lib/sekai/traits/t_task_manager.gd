class_name TTaskManager extends MonoTrait

var id := &"task_manager"

var requires := [&"kv_container"]

var props := {
	&"taskm/get_by_id": func(ctx, this: Mono, task_id: StringName) -> Variant:
		var tasks = this.getp(&"kvs") as Dictionary
		if not tasks.has(task_id):
			push_error("task/get_by_id: ", "task not found: ", task_id)
			return null

		var task = tasks[task_id] as Mono

		var task_data = task.getp(&"task_data")
		var task_status = task.getp(&"task_status")

		return {"data": task_data, "status": task_status}
		,

	&"taskm/get_by_status": func(ctx, this: Mono, status: int) -> Variant:
		var tasks = this.getp(&"kvs") as Dictionary
		var result = {}

		for i in tasks:
			var task = tasks[i] as Mono
			var task_data = task.getp(&"task_data")
			var task_status = task.getp(&"task_status")

			if status == -1 || status == task_status:
				result[i] = {"data": task_data, "status": task_status}

		return result
		,

	&"taskm/activate": func(ctx, this: Mono, task_id: StringName) -> bool:
		var tasks = this.getp(&"kvs") as Dictionary
		if not tasks.has(task_id):
			push_error("task/activate: ", "task not found: ", task_id)
			return false
		
		var task = tasks[task_id] as Mono
		
		if task.emitmRSUY(ctx, &"task/start"):
			this.applymR(ctx, &"on_status_changed", [task_id, TASK_STATUS.START])
			return true
		else:
			return false
		,

	&"taskm/deactivate": func(ctx, this: Mono, task_id: StringName) -> bool:
		var tasks = this.getp(&"kvs") as Dictionary
		if not tasks.has(task_id):
			push_error("task/deactivate: ", "task not found: ", task_id)
			return false
		
		var task = tasks[task_id] as Mono
		
		if task.emitmRSUY(ctx, &"task/stop"):
			this.applymR(ctx, &"on_status_changed", [task_id, TASK_STATUS.NOT_START])
			return true
		else:
			return false
		,
	
	&"taskm/update": func(ctx, this: Mono):
		var task_defines = await sekai.db.callm(sekai.context, &"db/getg", &"task")
		
		if task_defines == null:
			return
			
		for i in task_defines:
			if not await this.callm(ctx, &"kv/has", task_defines[i]["id"]):
				var mono = sekai.make_mono(4, {"task_data": task_defines[i]})
				await mono._into_container(ctx, this)
				this.applym(ctx, &"kv/set", [i, mono])
		,

	&"on_status_changed": Prop.Stack(),

	&"on_ready": Prop.puts({
		&"0:taskm": func(ctx, this: Mono):
			this.emitm(ctx, &"taskm/update")
			this.callm(ctx, &"db/setgw", &"vals")
			,
	}),
}

enum TASK_STATUS {
	NOT_START = 0,
	START = 1,
	COMPLETE = 2,
	FAIL = 3,
}
