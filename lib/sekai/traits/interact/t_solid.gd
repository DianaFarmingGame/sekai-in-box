class_name TSolid extends MonoTrait
## 这个 Trait 可以使 Mono 的移动受到碰撞和导航的规则限制

var id := &"solid"
var requires := [&"position"]

var props := {
	#
	# 配置
	#
	
	# 是否需要检测导航
	&"solid_will_route": true,
	
	# 是否需要检测碰撞
	&"solid_will_collide": true,
	
	# 当检测导航时，哪些被视为有效组别
	&"solid_route_group": [&""],
	
	# 当检测碰撞时，哪些被视为有效组别
	&"solid_collide_group": [&""],
	
	# 当检测碰撞时，使用什么矩形，同时利用这个矩形的中心作为导航的检测点
	&"solid_box": Rect2(-0.5, -0.5, 1, 1),
	
	# 当检测导航时，将检测点的 Z 轴偏移多少，主要用来确定导航的 Z 层使用而非用于细微偏移
	&"solid_route_zoffset": 0,
	
	
	
	#
	# 方法
	#
	
	# 测试是否可移动到某个位置
	&"solid_test_to": TSolid.test_pos,
	
	# 测试是否可移动到某个位置，按偏移计
	&"solid_test_move": func (ctx: LisperContext, this: Mono, offset: Vector3) -> bool:
		return await TSolid.test_pos(ctx, this, this.position + offset),
	
	
	
	#
	# 信号
	#
	
	# 当检测到任何碰撞 Mono 时触发
	# @params: Mono[]: 检测到的所有 Mono
	&"on_solid_collide_all": Prop.Stack(),
	
	# 当检测到组内的碰撞 Mono 时触发
	# @params: Mono[]: 检测到的所有 Mono
	&"on_solid_collide": Prop.Stack(),
	
	# 当检测到任何可导航 Mono 时触发
	# @params: Mono[]: 检测到的所有 Mono
	&"on_solid_route_all": Prop.Stack(),
	
	# 当检测到组内的可导航 Mono 时触发
	# @params: Mono[]: 检测到的所有 Mono
	&"on_solid_route": Prop.Stack(),
	
	
	
	#--------------------------------------------------------------------------#
	&"on_position": Prop.puts({
		&"-99:solid": func (ctx: LisperContext, this: Mono, pos: Vector3) -> Vector3:
			var box := this.getp(&"solid_box") as Rect2
			var route_zoffset := this.getp(&"solid_route_zoffset") as float
			box.position += Vector2(pos.x, pos.y)
			var route_group := this.getp(&"solid_route_group") as Array
			var collide_group := this.getp(&"solid_collide_group") as Array
			var hako := this.get_hako()
			var routes := await TSolid.do_route(ctx, this, hako, box.get_center(), int(pos.z + route_zoffset))
			var collides := await TSolid.do_collide(ctx, this, hako, box, int(pos.z))
			var groutes := routes.filter(func (m: Mono): return m.callmRSUY(ctx, &"group_intersects", route_group))
			var gcollides := collides.filter(func (m: Mono): return m.callmRSUY(ctx, &"group_intersects", collide_group))
			if (not this.getp(&"solid_will_route") or groutes.size() > 0) \
			and (not this.getp(&"solid_will_collide") or gcollides.size() == 0):
				this.callc(ctx, &"on_solid_route_all", routes)
				this.callc(ctx, &"on_solid_route", groutes)
				if collides.size() > 0: this.callc(ctx, &"on_solid_collide_all", collides)
				return pos
			else:
				if gcollides.size() > 0: this.callc(ctx, &"on_solid_collide", gcollides)
				return this.position,
	}),
	&"on_draw_debug": Prop.puts({
		&"99:solid_box": TSolid.draw_debug,
	} if ProjectSettings.get_setting(&"sekai/debug_draw_solid") else {})
}

static func test_pos(ctx: LisperContext, this: Mono, pos: Vector3) -> bool:
	var box := this.getp(&"solid_box") as Rect2
	var route_zoffset := this.getp(&"solid_route_zoffset") as float
	box.position += Vector2(pos.x, pos.y)
	var route_group := this.getp(&"solid_route_group") as Array
	var collide_group := this.getp(&"solid_collide_group") as Array
	var hako := this.get_hako()
	return \
		(not this.getp(&"solid_will_route") or \
			(await do_route_with_group(ctx, this, hako, box.get_center(), int(pos.z + route_zoffset), route_group))
			.size() > 0
		) and \
		(not this.getp(&"solid_will_collide") or \
			(await do_collide_with_group(ctx, this, hako, box, int(pos.z), collide_group))
			.size() == 0
		)

static func do_route(ctx: LisperContext, this: Mono, hako: Mono, pos: Vector2, z_pos: int) -> Array:
	return (await hako.applymRSU(ctx, &"collect_route", [pos, z_pos])) \
				.filter(func (m: Mono): return m != this)

static func do_route_with_group(ctx: LisperContext, this: Mono, hako: Mono, pos: Vector2, z_pos: int, group: Array) -> Array:
	return (await hako.applymRSU(ctx, &"collect_route", [pos, z_pos])) \
				.filter(func (m: Mono): return m != this and m.callmRSUY(ctx, &"group_intersects", group))

static func do_collide(ctx: LisperContext, this: Mono, hako: Mono, box: Rect2, z_pos: int) -> Array:
	return (await hako.applymRSU(ctx, &"collect_collide", [box, z_pos])) \
				.filter(func (m: Mono): return m != this)

static func do_collide_with_group(ctx: LisperContext, this: Mono, hako: Mono, box: Rect2, z_pos: int, group: Array) -> Array:
	return (await hako.applymRSU(ctx, &"collect_collide", [box, z_pos])) \
				.filter(func (m: Mono): return m != this and m.callmRSUY(ctx, &"group_intersects", group))

static func draw_debug(ctx: LisperContext, this: Mono, ctrl: SekaiControl, item: SekaiItem) -> void:
	var pos := Vector2(this.position.x, this.position.y - this.position.z * item.ratio_yz)
	var rbox := this.getp(&"solid_box") as Rect2
	var box := Rect2(pos + rbox.position, rbox.size)
	item.draw_rect(box, 0x0088ff88)
	item.draw_rect(box, 0x0022ffff, false)
	item.draw_line(Vector2(box.position.x, pos.y), Vector2(box.end.x, pos.y), 0x0022ffff)
	item.draw_line(Vector2(pos.x, box.position.y), Vector2(pos.x, box.end.y), 0x0022ffff)

