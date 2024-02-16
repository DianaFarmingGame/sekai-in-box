extends Control

var this: Mono
var context: LisperContext
var control: SekaiControl

func _ready() -> void:
	await this.applymRSU(context, &"inventory/open", [control, this])

func _enter_tree() -> void:
	this.putsB.call_deferred(&"on_input", [&"0:UI物品栏", _on_input])

func _exit_tree() -> void:
	this.delsB(&"on_input", &"0:UI物品栏")

func _on_input(ctx: LisperContext, this: Mono, ctrl: SekaiControl, sets: InputSet) -> void:
	if sets.pressings.has(&"inventory_toggle"): await this.applyc(ctx, &"on_inventory_toggle", [ctrl])
