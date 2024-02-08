extends Control

var this: Mono
var context: LisperContext

@onready var SlotList := %SlotList as VBoxContainer

func _ready() -> void:
	_update_slots(context, this)

func _enter_tree() -> void:
	this.putsB(&"on_slots_mod", [&"ui_slots", _update_slots])
	this.putsB(&"on_cur_slot_mod", [&"ui_slots", _update_slots])

func _exit_tree() -> void:
	this.delsB(&"on_slots_mod", &"ui_slots")
	this.delsB(&"on_cur_slot_mod", &"ui_slots")

var Slot := preload("slot.tscn")

func _update_slots(ctx: LisperContext, this: Mono) -> void:
	for child in SlotList.get_children():
		SlotList.remove_child(child)
	var cur := this.getp(&"cur_slot") as int
	var slots := this.emitmRSUY(ctx, &"slot/get_all") as Array
	var start := cur - int((slots.size() - 1) / 2)
	for i in range(start, start + slots.size()):
		var rcur := wrapi(i, 0, slots.size())
		var mono = slots[rcur]
		var texture = null
		if mono != null:
			texture = await (mono as Mono).emitmRS(ctx, &"icon/get_texture")
		var node := Slot.instantiate()
		node.shortcut_label = str(rcur + 1)
		node.active = cur == rcur
		if texture != null:
			node.texture = texture
		SlotList.add_child(node)
