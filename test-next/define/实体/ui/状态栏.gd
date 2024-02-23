class_name UI状态栏 extends MonoTrait

var id := &"UI状态栏"
var requires := [&"ui"]

var props := {
	#--------------------------------------------------------------------------#
	&"act_ui": Prop.pushs([&"status"]),
	&"ui_data": {
		&"status": preload("状态栏/status.tscn"),
	},
}
