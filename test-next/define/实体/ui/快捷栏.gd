class_name UI快捷栏 extends MonoTrait

var id := &"UI快捷栏"
var requires := [&"ui", &"有快捷栏"]

var props := {
	#--------------------------------------------------------------------------#
	&"act_ui": Prop.pushs([&"slots"]),
	&"ui_data": {
		&"slots": preload("快捷栏/main.tscn"),
	},
}
