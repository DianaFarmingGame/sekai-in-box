extends Control

@onready var sekai := $Sekai as Sekai
@onready var dialog_inner := %DialogInner as RichTextLabel
@onready var dialog_box := %DialogBox as Control
@onready var dialog = $dialog

var picture_dict = {
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
	sekai.external_fns.merge({
		&"show_dialog": func (_sekai, this: Mono, text: String):
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
			accept_event()
			dialog.hide()
	})

signal confirmed

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		skip_dialog = true
		confirmed.emit()
