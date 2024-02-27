extends Control

var this: Mono
var context: LisperContext
var control: SekaiControl

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
		var name = task["data"]["name"]
		var desc = task["data"]["desc"]
		var node = TaskButton.new()
		node.text = name
		node.desc = desc
		node.connect("press", _on_button_pressed)
		%CraftList.add_child(node)
		
func _on_button_pressed(desc: String):
	$describe.text = desc
