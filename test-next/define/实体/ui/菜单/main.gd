extends Control

var this: Mono

@onready var LoadWin := %LoadWin as Window
@onready var SaveWin := %SaveWin as Window
@onready var LoadGikouList := %LoadGikouList as ItemList
@onready var SaveGikouList := %SaveGikouList as ItemList

func _ready() -> void:
	pass

var _scanned_gikous := []

func _update_gikou_list() -> void:
	LoadGikouList.clear()
	SaveGikouList.clear()
	_scanned_gikous.clear()
	var dir = DirAccess.open(ProjectSettings.get_setting(&"sekai/gikou_store_dir"))
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if not dir.current_is_dir() and file_name.ends_with(".gikou"):
				var id := file_name.trim_suffix(".gikou")
				LoadGikouList.add_item(id.capitalize())
				SaveGikouList.add_item(id.capitalize())
				_scanned_gikous.append(id)
			file_name = dir.get_next()

func _on_load_btn_pressed() -> void:
	_update_gikou_list()
	LoadWin.show()


func _on_save_btn_pressed() -> void:
	await sekai.record_gikou()


func _on_save_more_btn_pressed() -> void:
	_update_gikou_list()
	SaveWin.show()


func _on_exit_btn_pressed() -> void:
	get_tree().quit()


func _on_load_win_close_requested() -> void:
	LoadWin.hide()


func _on_save_win_close_requested() -> void:
	SaveWin.hide()


func _on_load_win_confirmed() -> void:
	var sels := LoadGikouList.get_selected_items()
	if sels.size() > 0:
		var id := _scanned_gikous[sels[0]] as String
		await sekai.enter_gikou(id)
