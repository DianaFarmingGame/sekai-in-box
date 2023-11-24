class_name TAssert extends MonoTrait

var id := &"assert"

var props := {
	&"asserts": {},
}

var methods := {
	&"get_assert": func (sekai: Sekai, this: Mono, pid: StringName) -> Variant:
		return sekai.get_assert(this.get_prop(&"asserts")[pid]),
}
