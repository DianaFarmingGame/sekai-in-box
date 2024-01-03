class_name TADestroy extends MonoTrait

var id := &"adestroy"

var props := {
	&"need_destroy": false,
	
	&"on_init": Prop.puts({
		&"98:adestroy": func (_sekai, this: Mono) -> void:
			if this.getp(&"need_destroy"): this.destroy.call_deferred(),
	}),
}
