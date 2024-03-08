extends Control

var this: Mono
var context: LisperContext
var control: SekaiControl

const Slot = preload("res://test-next/define/实体/ui/合成台/slot.tscn")

func _ready() -> void:
	draw_task()

func _enter_tree() -> void:
	this.putsB.call_deferred(&"on_input", [&"0:UI任务栏", _on_input])

func _exit_tree() -> void:
	this.delsB(&"on_input", &"0:UI任务栏")

func _on_input(ctx: LisperContext, this: Mono, ctrl: SekaiControl, sets: InputSet) -> void:
	if sets.pressings.has(&"task_toggle"): await this.callmRSU(ctx, &"task/toggle", ctrl)
 
func draw_task():
	var tasks = await sekai.gikou.callm(context, &"taskm/get_by_status", 0)
	for task in tasks.values():
		var vname = task["data"]["name"]
		var desc = task["data"]["desc"]
		var rewards = task["data"]["rewards"]
		var node = TaskButton.new()
		node.text = vname
		node.desc = desc
		node.rewards = rewards
		node.connect("press", _on_button_pressed)
		%CraftList.add_child(node)
		
func _on_button_pressed(desc: String, rewards: Dictionary):
	$describe.text = desc
	for child in $HBoxContainer.get_children():
		child.queue_free()
	for id in rewards:
		if id == "money":
			continue
		var item = sekai.get_define(id)
		var slot = Slot.instantiate()
		slot.item_texture = item.get_prop(&"asserts")[&"icon"]
		slot.label = str(rewards[id])
		$HBoxContainer.add_child(slot)
		
