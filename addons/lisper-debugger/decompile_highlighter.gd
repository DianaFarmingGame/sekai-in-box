class_name DecompileHighlighter extends SyntaxHighlighter

var mark = null
var default_color = 0xffffff99
var mark_color = 0x88ff44ff

func update(proot: Variant, pmark = null) -> void:
	mark = null
	if proot != null:
		var root_str := Lisper.stringify_flatten(proot)
		if pmark != null:
			var rmark := calc_marks(0, proot, [pmark])
			if rmark.size() == 0: rmark = [0, root_str.length()]
			var poses := calc_poses(root_str, rmark)
			if poses.size() > 0:
				mark = poses

func calc_poses(string: String, marks: Array) -> Array:
	return marks.map(func (m):
		var slice := string.substr(0, m)
		var line := slice.count('\n')
		var column := slice.length() - slice.rfind('\n') - 1
		return [line, column])

func calc_marks(soffset: int, tag: Array, marks: Array) -> Array:
	for node in marks:
		if is_same(node, tag[0]):
			return [soffset, soffset + Lisper.stringify_flatten(tag).length()]
	var res := []
	for t in tag.slice(1):
		if t is String:
			soffset += t.length()
		else:
			res.append_array(calc_marks(soffset, t, marks))
			soffset += Lisper.stringify_flatten(t).length()
	return res

func _get_line_syntax_highlighting(line: int) -> Dictionary:
	if mark != null:
		var start := mark[0] as Array
		var end := mark[1] as Array
		if start[0] <= line and end[0] >= line:
			var opt := {}
			if start[0] < line:
				opt[0] = { &"color": mark_color }
			else:
				opt[0] = { &"color": default_color }
				opt[start[1]] = { &"color": mark_color }
			if end[0] == line:
				opt[end[1]] = { &"color": default_color }
			return opt
	return {0: { &"color": default_color }}

