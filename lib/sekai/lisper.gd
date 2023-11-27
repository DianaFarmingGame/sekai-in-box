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

static func List(items: Array) -> Array: return [&"list", items]

static func Token(name: StringName) -> Array: return [&"token", name]

static func Keyword(name: StringName) -> Array: return [&"keyword", name]

static func String(content: String) -> Array: return [&"string", content]

static func Bool(value: bool) -> Array: return [&"bool", value]

static func Number(value: float) -> Array: return [&"number", value]

static func Array(items: Array) -> Array: return [&"array", items]

static func Call(name: StringName, tails = null) -> Array:
	var body := [Token(name)]
	if tails != null: for tail in tails:
		body.append_array(tail)
	return List(body)

static var CommonContext := _make_common_context()

static func _make_common_context() -> Context:
	var ctx := Context.new()
	ctx.rawfns.merge({
		&"echo": func (ctx: Context, body: Array) -> void:
			var msg := []
			for item in body:
				var res = ctx.exec_node(item)
				msg.append(str(res))
			print(' '.join(msg)),
		&"raw": func (_ctx: Context, body: Array) -> Array:
			return body,
		&"eval": func (ctx: Context, body: Array) -> Variant:
			var result = null
			for item in body:
				var res = ctx.exec_node(item)
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
	ctx.functions.merge({
		&"debug": func (value) -> Variant:
			assert(false)
			return value,
		&"vec2": func (x_p = null, y = null) -> Vector2:
			if x_p == null: return Vector2()
			if y == null: return Vector2(x_p)
			return Vector2(x_p, y),
		&"vec3": func (x_p = null, y = null, z = null) -> Vector3:
			if x_p == null: return Vector3()
			if y == null: return Vector3(x_p)
			return Vector3(x_p, y, z),
		&"rect2": func (x_p = null, y_s = null, w = null, h = null) -> Rect2:
			if x_p == null: return Rect2()
			if y_s == null: return Rect2(x_p)
			if w == null: return Rect2(x_p, y_s)
			return Rect2(x_p, y_s, w, h),
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
	var fns := {}
	var vars := {}
	var source = null
	
	static func common() -> Context:
		return Lisper.CommonContext.fork()
	
	func clone() -> Context:
		var ctx := Context.new()
		ctx.parent = parent
		ctx.fns = fns
		ctx.vars = vars
		ctx.source = source
		return ctx
	
	func fork() -> Context:
		var ctx := Context.new()
		ctx.parent = weakref(self)
		return ctx
	
	func get_fn(name: StringName) -> Variant:
		var res = fns.get(name)
		return res if res != null else parent.get_fn(name) if parent != null else null
	
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
	
	func log_error(item: Array, msg) -> void:
		var src = get_source()
		if src != null and item.size() > 2:
			var offset := item[2] as Array
			var pre_src := (src as String).substr(offset[0], offset[1] - offset[0])
			var lines := pre_src.split('\n')
			var slnum := (src as String).count('\n', 0, offset[0]) if offset[0] > 0 else 0
			for i in lines.size():
				lines[i] = String.num_uint64(i + slnum + 1).lpad(4) + "|\t" + lines[i]
			printerr(msg, "\n", '\n'.join(lines))
		else:
			printerr(msg)
		print('')
	
	func exec_node(item: Array) -> Variant:
		match item[0]:
			&"number", &"bool", &"keyword", &"string":
				return item[1]
			&"list":
				var handle
				var head = item[1][0]
				if head[0] == &"token":
					var name = head[1]
					var body = (item[1] as Array).slice(1)
					handle = get_fn(name)
					if handle != null:
						return handle.call(self, body)
					handle = get_fn(name)
					if handle != null:
						return exec_node(handle.call(body))
					handle = get_fn(name)
					if handle != null:
						return handle.callv(body.map(exec_node))
					log_error(item, str("method not found: ", name))
					return null
				log_error(item, "unexpected call list head: " + head)
				return null
			&"token":
				return get_var(item[1])
			&"array":
				return (item[1] as Array).map(exec_node)
			&"map":
				return exec_map_part(item[1])
		log_error(item, str("unknown item: ", item))
		return null
	
	@warning_ignore("integer_division")
	func exec_map_part(pairs: Array) -> Dictionary:
		var res := {}
		for i in pairs.size() / 2:
			var k = exec_node(pairs[2 * i])
			var v = exec_node(pairs[2 * i + 1])
			res[k] = v
		return res
