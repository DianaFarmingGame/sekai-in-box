extends Control

var param: Dictionary

signal finished(choosen: int)

const Choice := preload("choice.tscn")

func _ready() -> void:
	if param.get(&"title") != null:
		%Title.text = param[&"title"]
	else:
		%Title.visible = false
	if param.get(&"avatar") != null:
		%Avatar.texture = param[&"avatar"]
	else:
		%Avatar.visible = false
	var choices := param.get(&"choices", []) as Array
	for i in choices.size():
		var entry := choices[i] as Dictionary
		var node := Choice.instantiate()
		node.text = entry.get(&"text")
		node.pressed.connect(func ():
			finished.emit(entry.get(&"value", i))
		)
		%ChoiceList.add_child(node)
