class_name 神变 extends MonoTrait

var id := &"神变"
var requires := [&"input"]

var props := {
	&"kami_zoom_origin_size": null,
	&"kami_zoom_delta": 0.1,
	
	&"on_input": Prop.puts({
		&"0:kami_zoom": func (ctx: LisperContext, this: Mono, ctrl: SekaiControl, sets: InputSet) -> void:
			for act in sets.pressings.keys():
				match act:
					&"kami_zoom_in": 神变.do_zoom(ctx, this, ctrl, 1)
					&"kami_zoom_out": 神变.do_zoom(ctx, this, ctrl, -1)
					&"kami_zoom_reset":
						var osize = this.getp(&"kami_zoom_origin_size")
						if osize != null:
							ctrl.unit_size = osize
			pass,
	}),
}

static func do_zoom(ctx: LisperContext, this: Mono, ctrl: SekaiControl, dir: int) -> void:
	if this.getp(&"kami_zoom_origin_size") == null:
		this.setpB(&"kami_zoom_origin_size", ctrl.unit_size)
	var delta := this.getp(&"kami_zoom_delta") as float
	var nsize := (ctrl.unit_size * pow(1 + delta, dir)).snapped(Vector3(1, 1, 1)).clamp(Vector3(8, 8, 8), Vector3(256, 256, 256))
	ctrl.unit_size = nsize
	pass
