class_name TTaskManager extends MonoTrait

var id := &"task_manager"

var requires := [&"kv_container"]

var props := {
	&"taskm/get_activate": func(ctx, this) -> Dictionary:
		return {}
		,

	&"taskm/activate": func(ctx, this: Mono, task_id: StringName) -> bool:
		var tasks = this.getp(&"kvs") as Dictionary
		if not tasks.has(task_id):
			push_error("task/activate: ", "task not found: ", task_id)
			return false
		
		var task = tasks[task_id] as Mono
		
		task.emitm(ctx, &"task/start")
		return true
		,
	
	&"taskm/update": func(ctx, this: Mono):
		var task_defines = await sekai.db.callm(sekai.context, &"db/getg", &"task") as Dictionary
		for i in task_defines:
			if not await this.callm(ctx, &"kv/has", task_defines[i]["id"]):
				var mono = sekai.make_mono(4, {"task_data": task_defines[i]})
				await mono._into_container(ctx, this)
				this.applym(ctx, &"kv/set", [i, mono])
		,

	&"on_ready": Prop.puts({
		&"0:taskm": func(ctx, this: Mono):
			this.emitm(ctx, &"taskm/update")
			this.callm(ctx, &"db/setgw", &"vals")
			,
	}),
}
