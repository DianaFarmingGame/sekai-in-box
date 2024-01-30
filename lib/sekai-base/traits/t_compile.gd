class_name TCompile extends MonoTrait

var id := &"compile"

var props := {
	&"compiled": false,
	&"compilers": Prop.Stack([]),
	
	&"on_init": Prop.puts({
		&"-999:compile": TCompile.update,
	}),
	&"on_restore": Prop.puts({
		&"-999:compile": TCompile.update,
	}),
}

static func update(this: Mono) -> void:
	if not this.getp(&"compiled"):
		await this.emitm(&"compilers")
		this.setpR(&"compiled", true)
