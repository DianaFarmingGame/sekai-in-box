extends Control

@onready var sekai := $Sekai as Sekai
@onready var dialog_inner := %DialogInner as RichTextLabel
@onready var dialog_box := %DialogBox as Control
@onready var dialog = $dialog

var picture_dict = {
	# ^Lane Sun: 使用 preload 可以用相对路径访问文件
	"嘉心糖": load("res://test/asset/ui/小然立绘/祈求.png"),
	"嘉然": load("res://test/asset/ui/小然立绘/生气.png"),
}

var skip_dialog := false

func _ready() -> void:
	dialog.hide()
	var tree := get_tree()
	tree.auto_accept_quit = false
	tree.root.close_requested.connect(func ():
		sekai.queue_free()
		remove_child(sekai)
		await tree.process_frame
		await tree.process_frame
		tree.quit())
	%SaveBtn.pressed.connect(func ():
		sekai.save_to_path("user://save.sekai"))
	%LoadBtn.pressed.connect(func ():
		sekai.load_from_path("user://save.sekai"))
	sekai.input_updated.connect(_on_input)
	
	sekai.external_fns.merge({
		&"dialog_say_to": func (_sekai, this: Mono, _meta: Dictionary, text: String):
			skip_dialog = false
			dialog.show()
			dialog.set_content(text)
			dialog.set_character_texture(picture_dict.get(this.getp(&"name")))
			dialog.set_character_name(this.getp(&"name"))
			dialog.set_visiable_content(0)
			while dialog.get_visiable_character_count() < dialog.get_total_character_count():
				await tree.create_timer(0.02).timeout
				if skip_dialog:
					dialog.set_visiable_content(dialog.get_total_character_count())
				dialog.set_visiable_content(dialog.get_visiable_character_count() + 1)
			await confirmed
			sekai.block_input()
			dialog.hide(),
		&"dialog_choose_single": func (psekai: Sekai, _this, _meta: Dictionary, title: String, choices: Array) -> int:
			var choose := [0]
			var update_inner_text := func ():
				var text := title
				for i in choices.size():
					if i == choose[0]:
						text += "\n  > " + choices[i]
					else:
						text += "\n    " + choices[i]
				dialog_inner.text = text
			update_inner_text.call()
			dialog_inner.visible_characters = 0
			dialog_box.visible = true
			skip_dialog = false
			while dialog_inner.visible_characters < dialog_inner.get_total_character_count():
				await tree.create_timer(0.02).timeout
				if skip_dialog:
					dialog_inner.visible_characters = dialog_inner.get_total_character_count()
				dialog_inner.visible_characters += 1
			while true:
				var inputs := await psekai.input_updating as Array
				sekai.block_input()
				if inputs[1].has(&"dialog_confirm"):
					break
				if inputs[1].has(&"ui_up"):
					choose[0] = wrapi(choose[0] - 1, 0, choices.size())
					update_inner_text.call()
					continue
				if inputs[1].has(&"ui_down"):
					choose[0] = wrapi(choose[0] + 1, 0, choices.size())
					update_inner_text.call()
					continue
			dialog_box.visible = false
			return choose[0],
	})

signal confirmed

func _on_input(_all, press: Dictionary, _release) -> void:
	if press.has(&"dialog_confirm"):
		skip_dialog = true
		confirmed.emit()
