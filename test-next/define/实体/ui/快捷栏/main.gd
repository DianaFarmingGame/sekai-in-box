extends Control

var this: Mono
var context: LisperContext

var can_modify := false:
	set(v):
		if v != can_modify:
			can_modify = v
			for entry in SlotList.get_children():
				entry.can_modify = can_modify

@onready var SlotList := %SlotList as HBoxContainer

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
		child.queue_free()
	var cur := this.getp(&"cur_slot") as int
	var slots := this.emitmRSUY(ctx, &"slot/get_all") as Array
	$Select.position = SlotList.position + Vector2(64 * cur -5,2)
	$Select.this = this
	$Select.context = context
	$Select.slot = cur
	for i in range(0, slots.size()):
		var rcur := wrapi(i, 0, slots.size())
		var mono = slots[rcur]
		var texture = null
		if mono != null:
			texture = await (mono as Mono).emitmRS(ctx, &"icon/get_texture")
		var node := Slot.instantiate()
		node.this = this
		node.context = context
		node.slot = rcur
		if texture != null:
			node.texture = texture
		node.can_modify = can_modify
		SlotList.add_child(node)

func _on_slot_list_resized():
	if(SlotList != null):
		$Select.position = SlotList.position + Vector2(64 * $Select.slot -5,2)
