extends Control

var this: Mono
var context: LisperContext
var control: SekaiControl

@onready var ItemBox := %ItemBox as VBoxContainer

func _ready() -> void:
	_update_contains(context, this)

func _enter_tree() -> void:
	this.putsB(&"on_contains_mod", [&"0:ui_inventory_view", _update_contains])

func _exit_tree() -> void:
	this.delsB(&"on_contains_mod", &"0:ui_inventory_view")

const ItemEntry := preload("entry.tscn")

func _update_contains(ctx: LisperContext, this: Mono) -> void:
	for child in ItemBox.get_children():
		ItemBox.remove_child(child)
	var contains := this.getp(&"contains") as Array
	for mono in contains:
		var texture = await (mono as Mono).emitmRS(ctx, &"icon/get_texture")
		var entry := ItemEntry.instantiate()
		if texture != null:
			entry.texture = texture
		entry.label = mono.getp(&"name")
		ItemBox.add_child(entry)
	print(contains)
