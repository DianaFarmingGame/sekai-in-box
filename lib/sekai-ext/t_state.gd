class_name TState extends MonoTrait

var id := &"state"

var props := {
	&"init_state": &"normal",
	&"cur_state": null,
	&"on_init": Prop.puts({
		&"0:state": func (_sekai, this: Mono):
			var init_state = this.getp(&"init_state")
			this.callm(&"state_to", init_state),
	}),
	&"state_to": func (_sekai, this: Mono, dist: StringName) -> void:
		var state_data = this.getp(&"state_data")
		var prev = this.getp(&"cur_state")
		if prev == dist: return
		if prev != null:
			var prev_data = state_data[prev]
			var exit = prev_data.get(&"on_exit")
			if exit != null: exit.call(_sekai, this, dist)
			this.uncover(&"state")
		if dist != null:
			var dist_data = state_data[dist]
			var cover = dist_data.get(&"cover")
			var enter = dist_data.get(&"on_enter")
			if cover != null: this.cover(&"state", cover)
			if enter != null: enter.call(_sekai, this, prev)
		this.setp(&"cur_state", dist),
	&"state_data": {},
}
