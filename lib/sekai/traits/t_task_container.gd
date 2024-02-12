class_name TTaskContainer extends MonoTrait

var id := &"task_container"

var props := {
	&"tasks": {},
	&"activate": {},

	&"task/get_activate": func(ctx, this, ) -> Dictionary:
		return {}
		,

	&"task/put": func(ctx, this: Mono, task: Dictionary):
		var tasks = this.getp(&"tasks") as Dictionary
		var task_id = task[id]
		if tasks.has(task_id):
			push_warning("[task/put] ", "define exist task: ", task_id)
		tasks[task_id] = task
		,

	&"task/activate": func(ctx, this: Mono, task_id: StringName) -> bool:
		var tasks = this.getp(&"tasks") as Dictionary
		if not tasks.has(task_id):
			push_error("task/activate: ", "task not found: ", task_id)
			return false
		
		var task = tasks[task_id] as Dictionary
		var activate = this.getp(&"activate") as Dictionary
		
		if activate.has(task_id):
			push_warning("[task/activate] ", "task already activated: ", task_id)
			return true

		activate[task_id] = task
		return true
		,
	
}

