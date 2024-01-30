class_name TGroup extends MonoTrait

var id := &"group"

var props := {
	&"groups": Prop.Stack([&""]),
	
	&"group_in": func (this: Mono, group: Variant) -> bool:
		return this.getp(&"groups").has(group),
	&"group_intersects": func (this: Mono, groups: Array) -> bool:
		return (this.getp(&"groups") as Array).any(func (g): return groups.has(g)),
}
