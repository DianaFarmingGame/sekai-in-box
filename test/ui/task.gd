extends TextureRect


func _ready():
	$HBoxContainer/TextureRect/space_item.picture = load("res://test/asset/ui/水壶.png")
	$HBoxContainer/TextureRect/space_item.num = 1
