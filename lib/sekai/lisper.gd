class_name Lisper

static func eval(expr: String) -> Variant:
	var ctx := Context.common()
	var res = ctx.eval(expr)
	return [ctx, res]

static func tokenize(expr: String) -> Variant:
	var parser := GispParser.make(expr)
	if parser.parse():
		return parser.get_result()
	else:
		return null

static func List(nodes: Array) -> Array: return [TType.LIST, nodes]

static func Token(name: StringName) -> Array: return [TType.TOKEN, name]

static func Keyword(name: StringName) -> Array: return [TType.KEYWORD, name]

static func String(content: String) -> Array: return [TType.STRING, content]

static func Bool(value: bool) -> Array: return [TType.BOOL, value]

static func Number(value: float) -> Array: return [TType.NUMBER, value]

static func Array(nodes: Array) -> Array: return [TType.ARRAY, nodes]

static func Call(name: StringName, tails = null) -> Array:
	var body := [Token(name)]
	if tails != null: for tail in tails:
		body.append_array(tail)
	return List(body)

static var CommonContext := _make_common_context()

static func _make_common_context() -> Context:
	var ctx := Context.new()
	ctx.def_fns(VarType.GD_RAW, {
		&"echo": func (ctx: Context, body: Array) -> void:
			var msg := []
			for node in body:
				var res = ctx.exec_node(node)
				msg.append(str(res))
			print(' '.join(msg)),
		&"raw": func (_ctx: Context, body: Array) -> Array:
			return body,
		&"eval": func (ctx: Context, body: Array) -> Variant:
			var result = null
			for node in body:
				var res = ctx.exec_node(node)
				result = ctx.exec_node(res)
			return result,
		&"defvar": func (ctx: Context, body: Array) -> void:
			var name = body[0][1]
			if name is String or name is StringName:
				var data = ctx.exec_node(body[1])
				ctx.def_var(name, data)
			else:
				ctx.log_error(body[0], str("defvar: ", body[0], " is not a valid token")),
	})
	ctx.def_fns(VarType.GD_CALL, {
		&"debug": func (value: Variant) -> Variant:
			assert(false)
			return value,
		&"vec2": func (x: float, y: float) -> Vector2:
			return Vector2(x, y),
		&"vec3": func (x: float, y: float, z: float) -> Vector3:
			return Vector3(x, y, z),
		&"rect2": func (x: float, y: float, w: float, h: float) -> Rect2:
			return Rect2(x, y, w, h),
		&"color": func (r_c = null, g_a = null, b = null, a = null) -> Color:
			if r_c == null: return Color()
			if g_a == null: return Color(r_c)
			if b == null: return Color(r_c, g_a)
			if a == null: return Color(r_c, g_a, b)
			return Color(r_c, g_a, b, a),
	})
	return ctx

static func test_parser() -> void:
	print(Lisper.tokenize("1 0 .5 10 204.2 3.30"))
	print(Lisper.tokenize("#t #f#t"))
	print(Lisper.tokenize("\"string\" \"quote\\\"ed\"\"nested\""))
	print(Lisper.tokenize("&keyword &+1 &&"))
	print(Lisper.tokenize("token t$&.#"))
	print(Lisper.tokenize("() (list tail) (nested (1 2 3))"))
	print(Lisper.tokenize("[] [array 1 2 3] [nested [1 2 3]]"))
	print(Lisper.tokenize("{} {&map [1 2 3] &nested {&id &123}}"))
	print(Lisper.tokenize("; comment\n token ; another comment"))
	print(Lisper.tokenize("#;[ skiper comment ]"))

static func test_common() -> void:
	print(Lisper.eval("""
		; Vector2
		(vec2)
		(vec2 2 1)
		
		; Rect2
		(rect2)
		(rect2 (vec2 10 10) (vec2 20 20))
		(rect2 (rect2 1 1 2 2))
		
		; Color
		(color)
		(color "#0088ff44")
		(color "#0088ff" 0.5)
		(color 0 0.5 1)
		(color (color 0 0.5 1 0.5))
	"""))

class Context:
	var parent = null
	var vars := {}
	var fixs := []
	var fix_map := {}
	var source = null
	
	static func common() -> Context:
		return Lisper.CommonContext.clone()
	
	static func common_fork() -> Context:
		return Lisper.CommonContext.fork()
	
	func clone() -> Context:
		var ctx := Context.new()
		ctx.parent = parent
		ctx.vars = vars.duplicate(true)
		ctx.fixs = fixs.duplicate(true)
		ctx.fix_map = fix_map.duplicate(true)
		ctx.source = source
		return ctx
	
	func fork() -> Context:
		var ctx := Context.new()
		ctx.fixs = fixs
		ctx.parent = self
		return ctx
	
	func get_var(name: StringName) -> Variant:
		var res = vars.get(name)
		return res if res != null else parent.get_var(name) if parent != null else null
	
	func set_var(name: StringName, data: Variant) -> Variant:
		var pdata = vars.get(name)
		if pdata != null:
			vars[name] = data
			return pdata
		return parent.set_var(name, data) if parent != null else null
	
	func def_var(name: StringName, data: Variant) -> void:
		vars[name] = data
	
	func def_fn(type: VarType, name: StringName, handle) -> void:
		vars[name] = [type, handle]
	
	func def_fns(type: VarType, handle_map: Dictionary) -> void:
		for k in handle_map.keys():
			vars[k] = [type, handle_map[k]]
	
	func eval(expr: String) -> Variant:
		var tokens = Lisper.tokenize(expr)
		source = expr
		if tokens != null:
			var res = exec(tokens)
			source = null
			return res
		else:
			push_error("failed to tokenize expression")
			return null
	
	func exec(tokens: Array) -> Variant:
		return tokens.map(exec_node)
	
	func get_source() -> Variant:
		return source if source != null else parent.get_source() if parent != null else null
	
	func log_error(node: Array, msg) -> void:
		var src = get_source()
		if src != null and node.size() > 2:
			var offset := node[2] as Array
			var pre_src := (src as String).substr(offset[0], offset[1] - offset[0])
			var lines := pre_src.split('\n')
			var slnum := (src as String).count('\n', 0, offset[0]) if offset[0] > 0 else 0
			for i in lines.size():
				lines[i] = String.num_uint64(i + slnum + 1).lpad(4) + "|\t" + lines[i]
			printerr(msg, "\n", '\n'.join(lines))
		else:
			printerr(msg)
		print('')
	
	func exec_node(node: Array) -> Variant:
		match node[0]:
			TType.TOKEN:
				return get_var(node[1])
			TType.NUMBER, TType.BOOL, TType.KEYWORD, TType.STRING:
				return node[1]
			TType.LIST:
				var head = node[1][0]
				var body = (node[1] as Array).slice(1)
				var handle = exec_node(head)
				if handle is Array:
					match handle[0]:
						VarType.GD_RAW:
							return handle[1].call(self, body)
						VarType.GD_MACRO:
							return exec_node(handle[1].call(body))
						VarType.GD_CALL:
							return handle[1].callv(body.map(exec_node))
						_:
							log_error(node, str("unknown call handle type: ", handle))
							return null
				elif handle == null:
					log_error(node, str("call handle not found: ", head))
				else:
					log_error(node, str("unexpected call handle: ", handle))
			TType.ARRAY:
				return (node[1] as Array).map(exec_node)
			TType.MAP:
				return exec_map_part(node[1])
		log_error(node, str("unknown node: ", node))
		return null
	
	@warning_ignore("integer_division")
	func exec_map_part(pairs: Array) -> Dictionary:
		var res := {}
		for i in pairs.size() / 2:
			var k = exec_node(pairs[2 * i])
			var v = exec_node(pairs[2 * i + 1])
			res[k] = v
		return res

enum TType {
	TOKEN,
	NUMBER,
	BOOL,
	KEYWORD,
	STRING,
	LIST,
	ARRAY,
	MAP,
}

enum VarType {
	VAR,
	GD_RAW,
	GD_MACRO,
	GD_CALL,
}

enum VarFlag {
	Pure,	# 纯函数，输出与输入绝对对应
	Fix,	# 固定点，定义可以修改但不能被掩盖
}
