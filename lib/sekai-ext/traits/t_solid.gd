class_name TSolid extends MonoTrait

var id := &"solid"
var requires := [&"position"]

var props := {
	&"solid_will_route": true,
	&"solid_will_collide": true,
	&"solid_route_group": [&""],
	&"solid_collide_group": [&""],
	&"solid_box": Rect2(-0.5, -0.5, 1, 1),
	&"solid_route_zoffset": 0,
	
	&"solid_test_to": TSolid.test_pos,
	&"solid_test_move": func (this: Mono, offset: Vector3) -> bool:
		return await TSolid.test_pos(sekai, this, this.position + offset),
	&"solid_to": func (this: Mono, pos: Vector3) -> void:
		if await TSolid.test_pos(sekai, this, pos):
			await this.callm(&"position_set", pos),
	&"solid_move": func (this: Mono, offset: Vector3) -> void:
		if await TSolid.test_pos(sekai, this, this.position + offset):
			await this.callm(&"position_move", offset),
	&"solid_collide_all_by": func (this: Mono, offset := Vector3()) -> Array:
		return await TSolid.collide_pos(sekai, this, this.position + offset),
	&"solid_collide_all_at": func (this: Mono, pos: Vector3) -> Array:
		return await TSolid.collide_pos(sekai, this, pos),
	&"solid_collide_by": func (this: Mono, offset := Vector3()) -> Array:
		var collide_group := this.getp(&"solid_collide_group") as Array
		return await Async.array_filter(await TSolid.collide_pos(sekai, this, this.position + offset), func (m): return m != this and await m.callm(&"group_intersects", collide_group)),
	&"solid_collide_at": func (this: Mono, pos: Vector3) -> Array:
		var collide_group := this.getp(&"solid_collide_group") as Array
		return await Async.array_filter(await TSolid.collide_pos(sekai, this, pos), func (m): return m != this and await m.callm(&"group_intersects", collide_group)),
	
	&"on_draw_debug": Prop.puts({
		&"99:solid_box": TSolid.draw_debug,
	} if ProjectSettings.get_setting(&"sekai/debug_draw_solid") else {})
}

static func test_pos(this: Mono, pos: Vector3) -> bool:
	var box := this.getp(&"solid_box") as Rect2
	var route_zoffset := this.getp(&"solid_route_zoffset") as float
	box.position += Vector2(pos.x, pos.y)
	var route_group := this.getp(&"solid_route_group") as Array
	var collide_group := this.getp(&"solid_collide_group") as Array
	return \
		(not this.getp(&"solid_will_route") or await Async.array_any(await sekai.will_route(box.get_center(), int(pos.z + route_zoffset)), func (m): return await m.callm(&"group_intersects", route_group))) and \
		(not this.getp(&"solid_will_collide") or (await Async.array_filter(await sekai.will_collide(box, int(pos.z)), func (m): return m != this and await m.callm(&"group_intersects", collide_group))).size() == 0)

static func collide_pos(this: Mono, pos: Vector3) -> Array:
	var box := this.getp(&"solid_box") as Rect2
	box.position += Vector2(pos.x, pos.y)
	return await sekai.will_collide(box, int(pos.z))

static func draw_debug(this: Mono, item: SekaiItem) -> void:
	var pos := Vector2(this.position.x, this.position.y - this.position.z * item.ratio_yz)
	var rbox := this.getp(&"solid_box") as Rect2
	var box := Rect2(pos + rbox.position, rbox.size)
	item.draw_rect(box, 0x0088ff88)
	item.draw_rect(box, 0x0022ffff, false)
	item.draw_line(Vector2(box.position.x, pos.y), Vector2(box.end.x, pos.y), 0x0022ffff)
	item.draw_line(Vector2(pos.x, box.position.y), Vector2(pos.x, box.end.y), 0x0022ffff)

