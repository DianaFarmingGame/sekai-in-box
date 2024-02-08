class_name UI物品栏 extends MonoTrait

var id := &"UI物品栏"
var requires := [&"ui", &"有背包"]

var props := {
	#--------------------------------------------------------------------------#
	&"ui_data": {
		&"inventory": preload("物品栏/main.tscn"),
	},
}
