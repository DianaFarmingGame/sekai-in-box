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
	&"solid_test_move": func (sekai: Sekai, this: Mono, offset: Vector3) -> bool:
		return TSolid.test_pos(sekai, this, this.position + offset),
	&"solid_to": func (sekai: Sekai, this: Mono, pos: Vector3) -> void:
		if TSolid.test_pos(sekai, this, pos):
			this.callm(&"position_set", pos),
	&"solid_move": func (sekai: Sekai, this: Mono, offset: Vector3) -> void:
		if TSolid.test_pos(sekai, this, this.position + offset):
			this.callm(&"position_move", offset),
	&"solid_collide_all_by": func (sekai: Sekai, this: Mono, offset := Vector3()) -> Array:
		return TSolid.collide_pos(sekai, this, this.position + offset),
	&"solid_collide_all_at": func (sekai: Sekai, this: Mono, pos: Vector3) -> Array:
		return TSolid.collide_pos(sekai, this, pos),
	&"solid_collide_by": func (sekai: Sekai, this: Mono, offset := Vector3()) -> Array:
		var collide_group := this.getp(&"solid_collide_group") as Array
		return TSolid.collide_pos(sekai, this, this.position + offset).filter(func (m): return m != this and m.callm(&"group_intersects", collide_group)),
	&"solid_collide_at": func (sekai: Sekai, this: Mono, pos: Vector3) -> Array:
		var collide_group := this.getp(&"solid_collide_group") as Array
		return TSolid.collide_pos(sekai, this, pos).filter(func (m): return m != this and m.callm(&"group_intersects", collide_group)),
}

static func test_pos(sekai: Sekai, this: Mono, pos: Vector3) -> bool:
	var box := this.getp(&"solid_box") as Rect2
	var route_zoffset := this.getp(&"solid_route_zoffset") as float
	box.position += Vector2(pos.x, pos.y)
	var route_group := this.getp(&"solid_route_group") as Array
	var collide_group := this.getp(&"solid_collide_group") as Array
	return \
		(not this.getp(&"solid_will_route") or sekai.will_route(box.get_center(), int(pos.z + route_zoffset)).any(func (m): return m.callm(&"group_intersects", route_group))) and \
		(not this.getp(&"solid_will_collide") or sekai.will_collide(box, int(pos.z)).filter(func (m): return m != this and m.callm(&"group_intersects", collide_group)).size() == 0)

static func collide_pos(sekai: Sekai, this: Mono, pos: Vector3) -> Array:
	var box := this.getp(&"solid_box") as Rect2
	box.position += Vector2(pos.x, pos.y)
	return sekai.will_collide(box, int(pos.z))

static func draw_debug(_sekai, this: Mono) -> void:
	var item := this.get_item() as SekaiItem
	var pos := Vector2(this.position.x, this.position.y)
	var rbox := this.getp(&"solid_box") as Rect2
	var box := Rect2(pos + rbox.position, rbox.size)
	item.draw_rect(box, 0x0000ff44)
	item.draw_rect(box, 0x0000ffff, false)

