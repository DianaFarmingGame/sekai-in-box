extends TextureRect

const ItemNode = preload("res://test/ui/space_item.tscn")

@onready var task_container = $list/VBoxContainer
@onready var reward_container = $HBoxContainer
@onready var title = $title
@onready var desc = $describe
var detail_list = []

func _ready():
	var list = [
		{
			"title": "摸一下呆毛",
			"describe": "任务描述：\n触碰一下逆鳞",
			"items":[
				{
					"picture": load("res://test/asset/ui/水壶.png"),
					"num": 1
				}
			]
		},
		{
			"title": "摸2下呆毛",
			"describe": "任务描述：\n触碰2下逆鳞",
			"items":[
				{
					"picture": load("res://test/asset/ui/水壶.png"),
					"num": 2
				}
			]
		},
		{
			"title": "摸3下呆毛",
			"describe": "任务描述：\n触碰3下逆鳞",
			"items":[
				{
					"picture": load("res://test/asset/ui/水壶.png"),
					"num": 3
				}
			]
		},
		{
			"title": "摸4下呆毛",
			"describe": "任务描述：\n触碰4下逆鳞",
			"items":[
				{
					"picture": load("res://test/asset/ui/水壶.png"),
					"num": 4
				}
			]
		}
	]
	clear()
	draw_task(list)
	
func draw_task(array: Array):
	detail_list = array
	for task in array:
		var button = CustomButton.new()
		button.text = task['title']
		button.connect("press", _on_button_pressed)
		task_container.add_child(button)
		
func clear():
	var children = task_container.get_children()
	for child in children:
		task_container.remove_child(child)
	title.text = ""
	desc.text = ""
	clear_reward()

func clear_reward():
	for i in range(3):
		var slot = reward_container.get_child(i)
		var children = slot.get_children()
		for child in children:
			slot.remove_child(child)

func _on_button_pressed(index):
	title.text = detail_list[index]['title']
	desc.text = detail_list[index]['describe']
	clear_reward()
	var items = detail_list[index]['items']
	for i in range(items.size()):
		var item = items[i]
		var picture = item['picture']
		var num = item['num']
		var node = ItemNode.instantiate()
		node.picture = picture
		node.num = num
		var slot = reward_container.get_child(i)
		slot.add_child(node)
