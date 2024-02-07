extends Control

const tags := [
	"神様思考中...",
	"神様俯视中...",
	"神様犹豫中...",
	"神様观察中...",
]

var this: Mono
var context: LisperContext

@onready var PickList := %PickList as ItemList
@onready var HoverInfo := %HoverInfo as Label

func _ready() -> void:
	%Tag.text = tags[randi_range(0, tags.size() - 1)]
	this.putsB(&"on_pick", [&"0:kami_ui", _on_kami_hover])
	this.putsB(&"on_action_primary", [&"0:kami_ui", _on_kami_pick])

func _on_kami_hover(ctx: LisperContext, this: Mono, ctrl: SekaiControl, pick: Variant, sets: InputSet) -> void:
	if pick != null:
		HoverInfo.text = str(pick.define.id, '[', pick.define.ref, '] ', pick.position.snapped(Vector3(0.1, 0.1, 0.1)))

var _pick_monos := []

func _on_kami_pick(ctx: LisperContext, this: Mono, ctrl: SekaiControl, pick: Variant, sets: InputSet) -> void:
	var dir := sets.direction
	var pos := Vector2(this.position.x, this.position.y - this.position.z * ctrl.unit_size.y / ctrl.unit_size.z) + dir
	var hako := this.get_hako()
	var res := await hako.applymRSU(ctx, &"collect_pick", [ctrl, pos]) as Array
	PickList.clear()
	for mono in _pick_monos:
		mono.setpW(context, &"layer_opacity", 1.0)
	_pick_monos.clear()
	if res.size() > 0:
		for entry in res:
			var mono := entry[1] as Mono
			PickList.add_item(str(mono.define.id, '[', mono.define.ref, '] ', mono.position.snapped(Vector3(0.1, 0.1, 0.1))))
			_pick_monos.append(mono)

func _on_pick_list_item_selected(index: int) -> void:
	for i in _pick_monos.size():
		var mono := _pick_monos[i] as Mono
		if i == index:
			mono.setpW(context, &"layer_opacity", 1.0)
		else:
			mono.setpW(context, &"layer_opacity", 0.2)
