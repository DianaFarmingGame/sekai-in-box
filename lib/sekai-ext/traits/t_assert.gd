class_name TAssert extends MonoTrait

var id := &"assert"

var props := {
	&"asserts": {},
	
	&"assert_get": func (this: Mono, pid: StringName) -> Variant:
		return sekai.get_assert(this.getp(&"asserts")[pid]),
}
