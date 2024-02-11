extends Control

var this: Mono
var context: LisperContext

var can_modify := false:
	set(v):
		if v != can_modify:
			can_modify = v
			for entry in SlotList.get_children():
				entry.can_modify = can_modify

@onready var SlotList := %SlotList as VBoxContainer

func _ready() -> void:
	_update_slots(context, this)

func _enter_tree() -> void:
	this.putsB(&"on_slots_mod", [&"0:ui_slots", _update_slots])
	this.putsB(&"on_cur_slot_mod", [&"0:ui_slots", _update_slots])

func _exit_tree() -> void:
	this.delsB(&"on_slots_mod", &"0:ui_slots")
	this.delsB(&"on_cur_slot_mod", &"0:ui_slots")

const Slot := preload("slot.tscn")

func _update_slots(ctx: LisperContext, this: Mono) -> void:
	for child in SlotList.get_children():
		SlotList.remove_child(child)
		child.free()
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
		node.this = this
		node.context = context
		node.slot = rcur
		node.shortcut_label = str(rcur + 1)
		node.active = cur == rcur
		if texture != null:
			node.texture = texture
		node.can_modify = can_modify
		SlotList.add_child(node)
