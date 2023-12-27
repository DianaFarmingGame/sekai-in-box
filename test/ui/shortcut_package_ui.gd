extends Control

const ItemNode = preload("res://test/ui/space_item.tscn")

var is_visible: bool
var space_name: String

signal move_item(from_space,from_index,to_space,to_index)
signal use_item(from_space,from_index)
signal select_item(from_space,from_index)

func _input(event):
	if Input.is_action_pressed("0"):
		slot_select(9)
	if Input.is_action_pressed("1"):
		slot_select(0)
	if Input.is_action_pressed("2"):
		slot_select(1)
	if Input.is_action_pressed("3"):
		slot_select(2)
	if Input.is_action_pressed("4"):
		slot_select(3)
	if Input.is_action_pressed("5"):
		slot_select(4)
	if Input.is_action_pressed("6"):
		slot_select(5)
	if Input.is_action_pressed("7"):
		slot_select(6)
	if Input.is_action_pressed("8"):
		slot_select(7)
	if Input.is_action_pressed("9"):
		slot_select(8)

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
	$Select.position = Vector2(-4 + index * 32,0)
