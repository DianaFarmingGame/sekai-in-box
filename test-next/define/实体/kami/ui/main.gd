extends Control

const TAGS := [
	"神様思考中...",
	"神様俯视中...",
	"神様犹豫中...",
	"神様观察中...",
]

var this: Mono
var context: LisperContext
var control: SekaiControl
var hako: Mono

@onready var DefineList := %DefineList as ItemList
@onready var DefineFilter := %DefineFilter as LineEdit
@onready var PickList := %PickList as ItemList
@onready var HoverInfo := %HoverInfo as Label
@onready var ActionTabs := %ActionTabs as TabContainer

func _ready() -> void:
	%Tag.text = TAGS.pick_random()
	hako = this.get_hako()
	_load_defines()

func _enter_tree() -> void:
	this.putsB(&"on_pick", [&"0:kami_ui", _on_kami_hover])
	#this.putsB(&"on_action_primary", [&"0:kami_ui", _on_kami_pick])
	#this.putsB(&"on_action_secondary", [&"0:kami_ui", _on_kami_pick_cancel])

func _exit_tree() -> void:
	this.delsB(&"on_pick", &"0:kami_ui")
	#this.delsB(&"on_action_primary", &"0:kami_ui")
	#this.delsB(&"on_action_secondary", &"0:kami_ui")

var _defines := []
var _filtered_defines := []
var _sel_define: MonoDefine = null

func _load_defines() -> void:
	for define in sekai.defines:
		if define != null:
			var label := str(define.name + ' ' if define.name else '') + str('@' + define.id if define.id else '') + str('[', define.ref ,']')
			_defines.append([label, define])
	_update_filtered_defines()

func _update_filtered_defines() -> void:
	_filtered_defines.clear()
	DefineList.clear()
	_sel_define = null
	for entry in _defines:
		var label := entry[0] as String
		var define := entry[1] as MonoDefine
		if DefineFilter.text == '' or label.contains(DefineFilter.text):
			_filtered_defines.append(define)
			DefineList.add_item(label)

func _on_define_filter_mod(new_text: String) -> void:
	_update_filtered_defines()

func _on_define_list_selected(index: int) -> void:
	_sel_define = _filtered_defines[index]

func _on_kami_hover(ctx: LisperContext, this: Mono, ctrl: SekaiControl, pick: Variant, sets: InputSet) -> void:
	if sets.triggered.has(&"action_primary"):
		_on_kami_pick(ctx, this, ctrl, pick, sets)
	if sets.triggered.has(&"action_secondary"):
		_on_kami_pick_cancel(ctx, this, ctrl, pick, sets)
	var dir := sets.direction
	var pos := (this.position + Vector3(dir.x, dir.y, 0)).round()
	if pick != null:
		HoverInfo.text = str(pos, " - ", pick.define.id, '[', pick.define.ref, '] ', pick.position.snapped(Vector3(0.1, 0.1, 0.1)))
	else:
		HoverInfo.text = str(pos)

var _pick_monos := []
var _sel_mono: Mono = null:
	set(v):
		if v != _sel_mono:
			if _sel_mono is Mono:
				_sel_mono.setpB(&"kami_select", null)
			if v is Mono:
				v.setpB(&"kami_select", true)
			_sel_mono = v
			_on_sel_mono_mod()

func _on_kami_pick(ctx: LisperContext, this: Mono, ctrl: SekaiControl, pick: Variant, sets: InputSet) -> void:
	if not _locked or sets.triggered.has(&"kami_force_select"):
		_on_kami_pick_cancel(ctx, this, ctrl, pick, sets)
		var dir := sets.direction
		var pos := Vector2(this.position.x, this.position.y - this.position.z * ctrl.unit_size.y / ctrl.unit_size.z) + dir
		var hako := this.get_hako()
		var res := await hako.applymRSU(ctx, &"collect_pick", [ctrl, pos]) as Array
		res.sort_custom(func (a, b): return a[0] < b[0])
		if res.size() > 0:
			for entry in res:
				var mono := entry[1] as Mono
				PickList.add_item(str(
					mono.getp(&"name") + ': ' if mono.getp(&"name") != null else '',
					str(mono.define.name) if mono.define.name != &"" else '',
					str('@', mono.define.id) if mono.define.id != &"" else '',
					'[', mono.define.ref, '] ',
					mono.position.snapped(Vector3(0.1, 0.1, 0.1))
				))
				_pick_monos.append(mono)
			PickList.select(0)
			_on_pick_list_item_selected(0)
	else:
		match ActionTabs.current_tab:
			ActionType.NONE:
				if _sel_define != null:
					var dir := sets.direction
					var pos := this.position + Vector3(dir.x, dir.y, 0)
					var mono := sekai.make_mono(_sel_define.ref, {
						&"position": pos
					})
					ctrl.hako.callmRSU(ctx, &"container/put", mono)
			ActionType.CHUNK:
				var chunk := _sel_mono
				var dir := sets.direction
				var pos := Vector2(this.position.x, this.position.y - this.position.z * ctrl.unit_size.y / ctrl.unit_size.z) + dir
				var offset := Vector2(chunk.position.x, chunk.position.y - chunk.position.z * ctrl.unit_size.y / ctrl.unit_size.z)
				var vsize := chunk.getp(&"chunk_size") as Vector2
				var cell := chunk.getp(&"chunk_cell") as Vector3
				var dcell := Vector2(cell.x, cell.y)
				var cpos := ((pos - offset) / dcell).snapped(Vector2(1, 1))
				if 0 <= cpos.x and cpos.x < vsize.x and 0 <= cpos.y and cpos.y < vsize.y:
					if _sel_define != null:
						chunk.applymRSU(ctx, &"chunk/set", [cpos, _sel_define.ref])

func _on_kami_pick_cancel(ctx: LisperContext, this: Mono, ctrl: SekaiControl, pick: Variant, sets: InputSet) -> void:
	if not _locked or sets.triggered.has(&"kami_force_select"):
		PickList.clear()
		for mono in hako.getp(&"contains"):
			mono.setpW(context, &"layer_opacity", 1.0)
		_pick_monos.clear()
		_sel_mono = null
	else:
		match ActionTabs.current_tab:
			ActionType.CHUNK:
				var chunk := _sel_mono
				var dir := sets.direction
				var pos := Vector2(this.position.x, this.position.y - this.position.z * ctrl.unit_size.y / ctrl.unit_size.z) + dir
				var offset := Vector2(chunk.position.x, chunk.position.y - chunk.position.z * ctrl.unit_size.y / ctrl.unit_size.z)
				var vsize := chunk.getp(&"chunk_size") as Vector2
				var cell := chunk.getp(&"chunk_cell") as Vector3
				var dcell := Vector2(cell.x, cell.y)
				var cpos := ((pos - offset) / dcell).snapped(Vector2(1, 1))
				if 0 <= cpos.x and cpos.x < vsize.x and 0 <= cpos.y and cpos.y < vsize.y:
					chunk.applymRSU(ctx, &"chunk/remove", [cpos])

func _on_pick_list_item_selected(index: int) -> void:
	#if _locked: return
	for mono in hako.getp(&"contains"):
		mono.setpW(context, &"layer_opacity", 0.2)
	_sel_mono = _pick_monos[index]
	_sel_mono.setpW(context, &"layer_opacity", 1.0)

var _locked := false

func _on_lock_toggled(toggled_on: bool) -> void:
	_locked = toggled_on

enum ActionType {
	NONE,
	BASE,
	CHUNK,
}

func _on_sel_mono_mod() -> void:
	var mono := _sel_mono
	var last_act := ActionType.NONE
	# 通常标签
	if mono is Mono:
		ActionTabs.set_tab_disabled(ActionType.BASE, false)
		last_act = ActionType.BASE
	else:
		ActionTabs.set_tab_disabled(ActionType.BASE, true)
	# 区块标签
	if mono is Mono and mono.define.id == &"chunk":
		ActionTabs.set_tab_disabled(ActionType.CHUNK, false)
		last_act = ActionType.CHUNK
	else:
		ActionTabs.set_tab_disabled(ActionType.CHUNK, true)
	ActionTabs.current_tab = last_act

func _on_take_control_btn_pressed() -> void:
	if _sel_mono != null:
		var ncontrol := SekaiControl.new(_sel_mono)
		var nwindow := Window.new()
		nwindow.initial_position = Window.WINDOW_INITIAL_POSITION_CENTER_SCREEN_WITH_MOUSE_FOCUS
		nwindow.size = Vector2i(600, 600)
		nwindow.add_child(ncontrol)
		add_child(nwindow)
		ncontrol.anchors_preset = Control.PRESET_FULL_RECT
		ncontrol.unit_size = control.unit_size
		nwindow.close_requested.connect(func ():
			nwindow.hide()
			remove_child(nwindow)
			nwindow.queue_free()
		)
		nwindow.show()

func _on_round_btn_pressed() -> void:
	sekai.gikou.callm(context, &"pass_round", 1)

func _on_chunk_set_btn_pressed() -> void:
	var chunk := _sel_mono
	if _sel_define != null:
		chunk.callmRSU(context, &"chunk/fill", _sel_define.ref)

func _on_put_button_pressed() -> void:
	var pos := Vector3(this.position.x, this.position.y, 1)
	control.hako.callmRSU(context, &"container/put", sekai.make_mono(&"实体/角色/嘉然", {
		&"position": pos
	}))
	control.hako.callmRSU(context, &"container/put", sekai.make_mono(&"实体/角色/嘉心糖", {
		&"position": pos
	}))
