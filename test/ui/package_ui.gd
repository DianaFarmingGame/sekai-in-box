extends Control

const ItemNode = preload("res://test/ui/space_item.tscn")

var is_visible: bool
var space_name: String

signal move_item(from_space,from_index,to_space,to_index)
signal remove_item(from_space,from_index)
signal use_item(from_space,from_index)
signal select_item(from_space,from_index)

func _ready():
	hide()
	is_visible = false

func _input(event):
	if event.is_action_pressed("open_package"):
		if is_visible:
			hide()
			is_visible = false
		else:
			show()
			is_visible = true
	
func draw_space(item_data: Array):
	var space = $ItemSpace
	clear_space()
	for i in range(item_data.size()):
		var item = item_data[i]
		if item == null:
			continue
		var picture = item['picture']
		var num = item['num']
		var node = ItemNode.instantiate()
		node.picture = picture
		node.num = num
		var slot = space.get_child(i)
		slot.add_child(node)
		
func clear_space():
	var space = $ItemSpace
	for i in space.get_child_count():
		var slot = space.get_child(i)
		var children = slot.get_children()
		for child in children:
			slot.remove_child(child)
		
func set_space(space_name: String):
	self.space_name = space_name
	
func slot_select(index: int):
	select_item.emit(space_name, index)
