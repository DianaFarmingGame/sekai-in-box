class_name TState extends MonoTrait

var id := &"state"

# TODO: 中间状态转移功能

var props := {
	&"init_state": &"normal",
	&"cur_state": null,
	&"on_init": Prop.puts({
		&"0:state": func (_sekai, this: Mono):
			var init_state = this.getp(&"init_state")
			await this.callm(&"state_to", init_state),
	}),
	&"on_store": Prop.puts({
		&"0:state": func (_sekai, this: Mono):
			var cur_state = this.getp(&"cur_state")
			this.setp(&"init_state", cur_state)
			await this.callm(&"state_to", null),
	}),
	&"on_restore": Prop.puts({
		&"0:state": func (_sekai, this: Mono):
			var init_state = this.getp(&"init_state")
			await this.callm(&"state_to", init_state),
	}),
	&"state_to": func (sekai: Sekai, this: Mono, dist: Variant) -> void:
		var state_data = this.getp(&"state_data")
		var prev = this.getp(&"cur_state")
		if prev == dist: return
		if prev != null:
			var prev_data = state_data[prev]
			var exit = prev_data.get(&"on_exit")
			if exit != null: sekai.gss_ctx.call_anyway(exit, [sekai, this, dist])
			this.uncover(&"state")
		if dist != null:
			var dist_data = state_data[dist]
			var cover = dist_data.get(&"cover")
			var enter = dist_data.get(&"on_enter")
			if cover != null: this.cover(&"state", cover)
			if enter != null: sekai.gss_ctx.call_anyway(enter, [sekai, this, prev])
		this.setp(&"cur_state", dist),
	&"state_data": {},
}
