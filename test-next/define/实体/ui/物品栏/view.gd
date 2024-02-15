extends Control

var this: Mono
var target: Mono
var context: LisperContext
var control: SekaiControl

@onready var ItemBox := %ItemBox as VBoxContainer

func _ready() -> void:
	var tname = target.getp(&"name")
	%Label.text = str(tname + "的物品" if tname != null else "物品")
	_update_contains(context, target)

func _enter_tree() -> void:
	target.putsB(&"on_contains_mod", [&"0:ui_inventory_view", _update_contains])

func _exit_tree() -> void:
	target.delsB(&"on_contains_mod", &"0:ui_inventory_view")

const ItemEntry := preload("entry.tscn")

func _update_contains(ctx: LisperContext, target: Mono) -> void:
	for child in ItemBox.get_children():
		ItemBox.remove_child(child)
	var contains := target.getp(&"contains") as Array
	for mono in contains:
		var entry := ItemEntry.instantiate()
		entry.this = mono
		entry.context = context
		entry.control = control
		ItemBox.add_child(entry)
