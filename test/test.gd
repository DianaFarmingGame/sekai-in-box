extends Control

@onready var sekai := $Sekai as Sekai
@onready var dialog_inner := %DialogInner as RichTextLabel
@onready var dialog_box := %DialogBox as Control

var skip_dialog := false

func _ready() -> void:
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
			var head: String = "[color=green]" + this.getp(&"name") + "：[/color]\n"
			dialog_inner.text = head + text
			dialog_inner.visible_characters = 0
			dialog_box.visible = true
			skip_dialog = false
			while dialog_inner.visible_characters < dialog_inner.get_total_character_count():
				await tree.create_timer(0.02).timeout
				if skip_dialog:
					dialog_inner.visible_characters = dialog_inner.get_total_character_count()
				dialog_inner.visible_characters += 1
			await confirmed
			accept_event()
			dialog_box.visible = false
	})
	sekai.input_updated.connect(_on_input)

signal confirmed

func _on_input(_all, press: Dictionary, _release) -> void:
	if press.has(&"dialog_confirm"):
		confirmed.emit()
