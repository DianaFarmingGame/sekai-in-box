extends Node

signal break_passed

var break_waiting := false:
	set(v):
		break_waiting = v
		PassBtn.disabled = not break_waiting

@onready var DebuggerWindow := %DebuggerWindow as Window
@onready var ContextList := %ContextList as ItemList
@onready var REPLInput := %REPLInput as CodeEdit
@onready var REPLOutput := %REPLOutput as TextEdit
@onready var ExecBtn := %ExecBtn as Button
@onready var TToggle := %TToggle as Button
@onready var CToggle := %CToggle as Button
@onready var JumpList := %JumpList as ItemList
@onready var StackList := %StackList as ItemList
@onready var DecompView := %DecompView as TextEdit
@onready var PassBtn := %PassBtn as Button
@onready var EvalBtn := %EvalBtn as Button
@onready var SDRawBtn := %SDRawBtn as Button
@onready var SDValBtn := %SDValBtn as Button
@onready var VarTree := %VarTree as Tree

var contexts := []
var cur_ctx = null
var ctx_stack := []

func _ready() -> void:
	if ProjectSettings.get_setting(&"lisper/debugger_visible"): DebuggerWindow.visible = true

func grab_focus() -> void:
	DebuggerWindow.visible = true
	DebuggerWindow.grab_focus()

func sign_context(name: String, ctx: LisperContext) -> void:
	contexts.append([name, ctx])
	update_contexts()
	ContextList.select(contexts.size() - 1)
	update_ctx_sel()

func unsign_context(name: String, ctx: LisperContext) -> void:
	for i in contexts.size():
		if contexts[i][0] == name and contexts[i][1] == ctx:
			contexts.remove_at(i)
			break
	update_contexts()

func output(msg: String, color = null, head_prefix := "", body_prefix = null, tail_prefix = null, single_prefix = null) -> void:
	if body_prefix == null: body_prefix = head_prefix
	if tail_prefix == null: tail_prefix = body_prefix
	if single_prefix == null: single_prefix = head_prefix
	var lines := msg.split('\n')
	if lines.size() == 1 : msg = single_prefix + lines[0]
	else:
		lines[0] = head_prefix + lines[0]
		lines[-1] = tail_prefix + lines[-1]
		for i in lines.size() - 2:
			lines[i + 1] = body_prefix + lines[i + 1]
		msg = '\n'.join(lines)
	var end := REPLOutput.get_line_count()
	REPLOutput.set_line(end - 1, REPLOutput.get_line(end - 1) + '\n')
	REPLOutput.set_line(end, msg)
	if color != null:
		for i in lines.size():
			REPLOutput.set_line_background_color(end + i, color)
	output_scroll_to_end.call_deferred()
	REPLOutput.queue_redraw()

func output_clear_bg(start: int, end: int) -> void:
	for i in end - start:
		REPLOutput.set_line_background_color(start + i, 0x00000000)

func output_scroll_to_end() -> void:
	var end := REPLOutput.get_line_count()
	REPLOutput.scroll_vertical = end

func update_contexts() -> void:
	var prev_sels := ContextList.get_selected_items()
	ContextList.deselect_all()
	ContextList.clear()
	for entry in contexts:
		ContextList.add_item(entry[0])
	if prev_sels.size() and prev_sels[0] < ContextList.item_count: ContextList.select(prev_sels[0])
	elif ContextList.item_count > 0: ContextList.select(0)
	await update_ctx_sel()

func update_ctx_sel() -> void:
	var sels := ContextList.get_selected_items()
	if sels.size() > 0:
		await get_tree().process_frame
		ctx_stack = []
		StackList.clear()
		var base_ctx = contexts[sels[0]][1]
		var ctx = base_ctx
		var i := 0
		while ctx != null and ctx.jumps.size() > 0:
			ctx_stack.append(ctx)
			var call_jump = ctx.jumps[-1]
			var disp := ctx.stringify(call_jump) as String
			StackList.add_item(str(i, ':') + disp.replace(' ', '').replace('\t', ''))
			StackList.set_item_tooltip(i, disp)
			ctx = ctx.parent
			i += 1
		if StackList.item_count > 0:
			StackList.select(0)
			StackList.item_selected.emit(0)
		else:
			cur_ctx = base_ctx
			update_ctx()
	else:
		ctx_stack = []
		StackList.clear()
		cur_ctx = null
		update_ctx()

func update_ctx() -> void:
	JumpList.clear()
	if cur_ctx != null:
		REPLInput.editable = true
		ExecBtn.disabled = false
		var ctx := cur_ctx as LisperContext
		for i in ctx.jumps.size():
			var jump = ctx.jumps[ctx.jumps.size() - i - 1]
			var disp := ctx.stringify(jump)
			JumpList.add_item(str(i, ':') + disp.replace(' ', '').replace('\t', ''))
			JumpList.set_item_tooltip(i, disp)
		if JumpList.item_count > 0:
			JumpList.select(0)
			JumpList.item_selected.emit(0)
		update_vars()
	else:
		REPLInput.editable = false
		ExecBtn.disabled = true

func update_vars() -> void:
	var ctx := cur_ctx as LisperContext
	VarTree.clear()
	var root = VarTree.create_item()
	VarTree.hide_root = true
	VarTree.columns = 2
	VarTree.column_titles_visible = true
	VarTree.set_column_title(0, "Name")
	VarTree.set_column_title_alignment(0, HORIZONTAL_ALIGNMENT_LEFT)
	VarTree.set_column_title(1, "F")
	VarTree.set_column_title_alignment(1, HORIZONTAL_ALIGNMENT_LEFT)
	var ks := ctx.vars.keys()
	for ik in ks.size():
		var k = ks[-ik - 1]
		var item := VarTree.create_item(root)
		item.set_text(0, k)
		item.set_text(1, "C" if ctx.vars[k][0].has(Lisper.VarFlag.CONST) else "")
		item.set_meta(&"ref", k)

var _decomp_tag = null
var _decomp_sel = null:
	set(v):
		_decomp_sel = v
		if _decomp_sel != null:
			EvalBtn.disabled = false
			SDRawBtn.disabled = false
			SDValBtn.disabled = false
		else:
			EvalBtn.disabled = true
			SDRawBtn.disabled = true
			SDValBtn.disabled = true

func do_decompile(node, mark = null) -> void:
	var tag := cur_ctx.stringify_rich(node) as Array
	DecompView.text = Lisper.stringify_flatten(tag)
	var highlighter := DecompileHighlighter.new()
	highlighter.update(tag, mark)
	DecompView.syntax_highlighter = highlighter
	_decomp_tag = tag

var _last_eval_start := 0
var _last_eval_end := 0

var _history := []
var _cur_history := 0

func do_exec_repl() -> void:
	var expr := REPLInput.text
	await exec_expr(expr)

func exec_expr(expr: String, revt := false) -> void:
	if expr.length() > 0:
		REPLInput.set_text.call_deferred("")
		output_clear_bg(_last_eval_start, _last_eval_end)
		_last_eval_start = REPLOutput.get_line_count()
		output(expr, 0x0088ff33, "   ~ ", "     ")
		var tokens := Lisper.tokenize(expr)
		if TToggle.button_pressed: output(cur_ctx.stringifys(tokens), 0x0088ff22, " T ┌ ", "   │ ", "   └ ", " T [ ")
		var compiles := cur_ctx.compiles(tokens) as Array
		if CToggle.button_pressed: output(cur_ctx.stringifys(compiles), 0x0088ff22, " C ┌ ", "   │ ", "   └ ", " C [ ")
		var psealed = cur_ctx.sealed; cur_ctx.sealed = false
		var results := await (cur_ctx as LisperContext).execs(compiles)
		cur_ctx.sealed = psealed
		for res in results:
			output(cur_ctx.stringify_raw(res, 0, 0, revt), 0x0088ff22, ">>>> ", "     ")
		_last_eval_end = REPLOutput.get_line_count()
		_history.append(expr)
		_cur_history = _history.size()
		update_vars()

func _on_repl_input_gui_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		match event.as_text_key_label():
			"Ctrl+Enter":
				do_exec_repl()
			"Ctrl+Up":
				_on_prev_btn_pressed()
			"Ctrl+Down":
				_on_next_btn_pressed()

func _on_exec_btn_pressed() -> void:
	do_exec_repl()

func _on_context_list_item_selected(index: int) -> void:
	update_ctx_sel()

func _on_prev_btn_pressed() -> void:
	_cur_history = clampi(_cur_history - 1, 0, _history.size())
	if _cur_history < _history.size(): REPLInput.text = _history[_cur_history]
	else: REPLInput.text = ""
	REPLInput.select_all()

func _on_next_btn_pressed() -> void:
	_cur_history = clampi(_cur_history + 1, 0, _history.size())
	if _cur_history < _history.size(): REPLInput.text = _history[_cur_history]
	else: REPLInput.text = ""
	REPLInput.select_all()

func _on_pass_btn_pressed() -> void:
	break_passed.emit()

func _on_jump_list_item_selected(index: int) -> void:
	if index < cur_ctx.jumps.size():
		do_decompile(cur_ctx.jumps[-index - 1], cur_ctx.jumps[-index] if index > 0 else null)

func _on_refresh_btn_pressed() -> void:
	update_ctx()

func _on_var_tree_item_activated() -> void:
	var item := VarTree.get_selected()
	var vname := item.get_meta(&"ref")
	exec_expr(vname)

func _on_stack_list_item_selected(index: int) -> void:
	cur_ctx = ctx_stack[index]
	update_ctx()

func _update_decomp_sel() -> void:
	if DecompView.get_caret_count() > 0:
		var line := DecompView.get_caret_line()
		var column := DecompView.get_caret_column()
		if _decomp_tag != null:
			var res = Lisper.stringify_find_pos(_decomp_tag, column, line)
			if res != null:
				_decomp_sel = res[0]
				var start := res[2][0] as Array
				var end := res[2][1] as Array
				DecompView.select.call_deferred(start[0], start[1], end[0], end[1])

func _on_decomp_view_caret_changed() -> void:
	_update_decomp_sel()

func _on_decomp_view_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		_update_decomp_sel()

var _sd_count := 0

func _on_sd_raw_btn_pressed() -> void:
	if _decomp_sel != null:
		var name := str("temp", _sd_count)
		_sd_count += 1
		var psealed = cur_ctx.sealed; cur_ctx.sealed = false
		cur_ctx.def_var([], name, _decomp_sel)
		await exec_expr(name, true)
		cur_ctx.sealed = psealed

func _on_sd_val_btn_pressed() -> void:
	if _decomp_sel != null:
		var name := str("temp", _sd_count)
		_sd_count += 1
		var psealed = cur_ctx.sealed; cur_ctx.sealed = false
		cur_ctx.def_var([], name, await cur_ctx.exec(_decomp_sel))
		await exec_expr(name, false)
		cur_ctx.sealed = psealed

func _on_eval_btn_pressed() -> void:
	if _decomp_sel != null:
		var name := ":eval"
		_sd_count += 1
		var psealed = cur_ctx.sealed; cur_ctx.sealed = false
		cur_ctx.def_var([], name, await cur_ctx.exec(_decomp_sel))
		await exec_expr(name, false)
		cur_ctx.undef_var(name)
		cur_ctx.sealed = psealed
		update_vars()

func _on_debugger_window_close_requested() -> void:
	DebuggerWindow.visible = false
