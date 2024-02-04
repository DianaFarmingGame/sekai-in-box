class_name TSolid extends MonoTrait

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
	
	&"solid_test_to": TSolid.test_pos,
	&"solid_test_move": func (ctx: LisperContext, this: Mono, offset: Vector3) -> bool:
		return await TSolid.test_pos(ctx, this, this.position + offset),
	&"solid_collide_all_by": func (ctx: LisperContext, this: Mono, offset := Vector3()) -> Array:
		return await TSolid.collide_pos(ctx, this, this.position + offset),
	&"solid_collide_all_at": func (ctx: LisperContext, this: Mono, pos: Vector3) -> Array:
		return await TSolid.collide_pos(ctx, this, pos),
	&"solid_collide_by": func (ctx: LisperContext, this: Mono, offset := Vector3()) -> Array:
		var collide_group := this.getp(&"solid_collide_group") as Array
		return await Async.array_filter(await TSolid.collide_pos(ctx, this, this.position + offset), func (m): return m != this and await m.callm(ctx, &"group_intersects", collide_group)),
	&"solid_collide_at": func (ctx: LisperContext, this: Mono, pos: Vector3) -> Array:
		var collide_group := this.getp(&"solid_collide_group") as Array
		return await Async.array_filter(await TSolid.collide_pos(ctx, this, pos), func (m): return m != this and await m.callm(ctx, &"group_intersects", collide_group)),
	
	
	
	#----------------------------------------------------------------------------------------------#
	&"on_position": Prop.puts({
		&"-99:solid": func (ctx: LisperContext, this: Mono, pos: Vector3) -> Vector3:
			if await TSolid.test_pos(ctx, this, pos):
				return pos
			else:
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
			(await Async.array_any(
				await hako.applymRSU(ctx, &"collect_route", [box.get_center(), int(pos.z + route_zoffset)]),
				func (m): return await m.callm(ctx, &"group_intersects", route_group),
			))
		) and \
		(not this.getp(&"solid_will_collide") or \
			(await Async.array_filter(
				await hako.applymRSU(ctx, &"collect_collide", [box, int(pos.z)]),
				func (m): return m != this and await m.callm(ctx, &"group_intersects", collide_group),
			)).size() == 0
		)

static func collide_pos(ctx: LisperContext, this: Mono, pos: Vector3) -> Array:
	var box := this.getp(&"solid_box") as Rect2
	box.position += Vector2(pos.x, pos.y)
	var hako := this.get_hako()
	return await hako.applymRSU(ctx, &"collect_collide", [box, int(pos.z)])

static func draw_debug(ctx: LisperContext, this: Mono, item: SekaiItem) -> void:
	var pos := Vector2(this.position.x, this.position.y - this.position.z * item.ratio_yz)
	var rbox := this.getp(&"solid_box") as Rect2
	var box := Rect2(pos + rbox.position, rbox.size)
	item.draw_rect(box, 0x0088ff88)
	item.draw_rect(box, 0x0022ffff, false)
	item.draw_line(Vector2(box.position.x, pos.y), Vector2(box.end.x, pos.y), 0x0022ffff)
	item.draw_line(Vector2(pos.x, box.position.y), Vector2(pos.x, box.end.y), 0x0022ffff)

