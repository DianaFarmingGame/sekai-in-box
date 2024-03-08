class_name 神移 extends MonoTrait

var id := &"神移"
var requires := [&"input", &"position"]

var props := {
	&"solid_will_route": false,
	&"solid_will_collide": false,
	
	&"kami_moving": false,
	&"kami_move_anchor_dir": Vector2(0, 0),
	&"kami_move_anchor_pos": Vector3(0, 0, 0),
	
	&"on_input": Prop.puts({
		&"0:kami_move": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, sets: InputSet) -> void:
			if sets.pressings.has(&"kami_move"):
				this.setpB(&"kami_moving", true)
				this.setpB(&"kami_move_anchor_dir", sets.direction)
				this.setpB(&"kami_move_anchor_pos", this.position)
			elif this.getp(&"kami_moving"):
				var anchor_dir := this.getp(&"kami_move_anchor_dir") as Vector2
				var anchor_pos := this.getp(&"kami_move_anchor_pos") as Vector3
				var delta_dir := anchor_dir - sets.direction
				await this.callmRSU(ctx, &"position/set", anchor_pos + Vector3(delta_dir.x, delta_dir.y, 0))
				if sets.releasings.has(&"kami_move"):
					this.setpB(&"kami_moving", false)
			for act in sets.pressings.keys():
				match act:
					&"kami_move_up":
						if not sets.pressings.has(&"kami_zoom_in"):
							await this.callmRSU(ctx, &"position/set", this.position + Vector3(0, 0, 1))
					&"kami_move_down":
						if not sets.pressings.has(&"kami_zoom_out"):
							await this.callmRSU(ctx, &"position/set", this.position - Vector3(0, 0, 1))
			pass,
	}),
}
