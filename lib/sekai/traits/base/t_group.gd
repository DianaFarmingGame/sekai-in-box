class_name TGroup extends MonoTrait
## 这个 Trait 用于为 Mono 提供分组功能

var id := &"group"

var props := {
	#
	# 配置
	#
	
	# Mono 所属的组别，&"" 是默认组
	&"groups": Prop.Stack([&""]),
	
	
	
	#
	# 方法
	#
	
	# 判断当前 Mono 是否在某个组内
	&"group/in": func (ctx: LisperContext, this: Mono, group: Variant) -> bool:
		return this.getp(&"groups").has(group),
	
	# 判断当前 Mono 是否和一个组的集合有交集
	&"group/intersects": func (ctx: LisperContext, this: Mono, groups: Array) -> bool:
		return (this.getp(&"groups") as Array).any(func (g): return groups.has(g)),
}
