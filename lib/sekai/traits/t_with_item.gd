class_name TWithItem extends MonoTrait

var id := &"with_sekai_item"

var props := {
	&"sekai_item": null,
	
	&"on_control_enter": Prop.puts({
		&"0:with_sekai_item": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
			var item := SekaiItem.new()
			this.setpB(&"sekai_item", item)
			ctrl.add_child(item),
	}),
	&"on_control_exit": Prop.puts({
		&"0:with_sekai_item": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl) -> void:
			var item := this.getpB(&"sekai_item") as SekaiItem
			this.setpB(&"sekai_item", null)
			ctrl.remove_child(item),
	}),
}
