class_name TGroup extends MonoTrait

var id := &"group"

var props := {
	&"groups": Prop.Stack([&""]),
	
	&"group_in": func (_sekai, this: Mono, group: Variant) -> bool:
		return this.getp(&"groups").has(group),
	&"group_intersects": func (_sekai, this: Mono, groups: Array) -> bool:
		return (this.getp(&"groups") as Array).any(func (g): return groups.has(g)),
}
