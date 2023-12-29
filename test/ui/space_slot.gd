extends TextureButton

class_name SpaceSlot

func _ready():
	self.connect("pressed", Callable(self, "_on_button_pressed"))

func _can_drop_data(_position, data):
	return data is Dictionary and data.has("index")

func _drop_data(_position, data):
	var from_space = data["space"]
	var from_index = data["index"]
	var to_space = self.get_parent().get_parent().space_name
	var to_index = self.get_index()
	print("emit signal")
	$"../..".move_item.emit(from_space,from_index,to_space,to_index)

func _input(event):
	# 检测鼠标右键是否按下
	if event is InputEventMouseButton and event.button_index == MouseButton.MOUSE_BUTTON_RIGHT and event.pressed:
		var rect = get_rect()
		rect.position += get_screen_position()
		# 检测鼠标是否在当前节点上
		if rect.has_point(event.position):
			var space = self.get_parent().get_parent().space_name
			var index = self.get_index()
			$"../..".use_item.emit(space,index)

func _on_button_pressed():
	$"../..".slot_select(get_index())
