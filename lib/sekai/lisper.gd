class_name Lisper

static func eval(expr: String) -> Variant:
	var ctx := Context.common()
	var res = ctx.eval(expr)
	return [ctx, res]

static func tokenize(expr: String) -> Variant:
	var parser := Parser.new(Stream.new(expr))
	if parser.r_root():
		return parser.result
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
				var res = ctx.exec_item(item)
				msg.append(str(res))
			print(' '.join(msg)),
		&"raw": func (_ctx: Context, body: Array) -> Array:
			return body,
		&"eval": func (ctx: Context, body: Array) -> Variant:
			var result = null
			for item in body:
				var res = ctx.exec_item(item)
				result = ctx.exec_item(res)
			return result,
		&"defvar": func (ctx: Context, body: Array) -> Variant:
			var name = body[0][1]
			if name is String or name is StringName:
				var data = ctx.exec_item(body[1])
				return ctx.def_var(name, data)
			else:
				ctx.log_error(body[0], str("defvar: ", body[0], " is not a valid token"))
				return null,
	})
	ctx.functions.merge({
		&"debug": func (value) -> Variant:
			assert(false)
			return value,
		&"vec2": func (x_p = null, y = null) -> Vector2:
			if x_p == null: return Vector2()
			if y == null: return Vector2(x_p)
			return Vector2(x_p, y),
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
	print(Lisper.tokenize("; comment\n token ; another comment"))

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
	var rawfns := {}
	var macros := {}
	var functions := {}
	var vars := {}
	var source = null
	
	static func common() -> Context:
		return Lisper.CommonContext.fork()
	
	func clone() -> Context:
		var ctx := Context.new()
		ctx.parent = parent
		ctx.rawfns = rawfns
		ctx.macros = macros
		ctx.functions = functions
		ctx.vars = vars
		ctx.source = source
		return ctx
	
	func fork() -> Context:
		var ctx := Context.new()
		ctx.parent = weakref(self)
		return ctx
	
	func get_rawfn(name: StringName) -> Variant:
		var handle = rawfns.get(name)
		if handle != null:
			return handle
		else:
			var par = parent.get_ref() if parent != null else null
			return par.get_rawfn(name) if par != null else null
	
	func get_macro(name: StringName) -> Variant:
		var handle = macros.get(name)
		if handle != null:
			return handle
		else:
			var par = parent.get_ref() if parent != null else null
			return par.get_macro(name) if par != null else null
	
	func get_func(name: StringName) -> Variant:
		var handle = functions.get(name)
		if handle != null:
			return handle
		else:
			var par = parent.get_ref() if parent != null else null
			return par.get_func(name) if par != null else null
	
	func get_var(name: StringName) -> Variant:
		var data = vars.get(name)
		if data != null:
			return data
		else:
			var par = parent.get_ref() if parent != null else null
			return par.get_var(name) if par != null else null
	
	func set_var(name: StringName, data: Variant) -> Variant:
		var pdata = vars.get(name)
		if pdata != null:
			vars[name] = data
			return pdata
		else:
			var par = parent.get_ref() if parent != null else null
			return par.set_var(name, data) if par != null else null
	
	func def_var(name: StringName, data: Variant) -> Variant:
		var pdata = vars.get(name)
		vars[name] = data
		return pdata
	
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
		return tokens.map(exec_item)
	
	func get_source() -> Variant:
		var par = parent.get_ref() if parent != null else null
		if source != null or par == null: return source
		return par.get_source()
	
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
	
	func exec_item(item: Array) -> Variant:
		match item[0]:
			&"number", &"bool", &"keyword", &"string":
				return item[1]
			&"array":
				return (item[1] as Array).map(exec_item)
			&"map":
				return exec_map_part(item[1])
			&"token":
				return get_var(item[1])
			&"list":
				var handle
				var head = item[1][0]
				if head[0] == &"token":
					var name = head[1]
					var body = (item[1] as Array).slice(1)
					handle = get_rawfn(name)
					if handle != null:
						return handle.call(self, body)
					handle = get_macro(name)
					if handle != null:
						return exec_item(handle.call(body))
					handle = get_func(name)
					if handle != null:
						return handle.callv(body.map(exec_item))
					log_error(item, str("method not found: ", name))
					return null
				log_error(item, "unexpected call list head: " + head)
				return null
		log_error(item, str("unknown item: ", item))
		return null
	
	@warning_ignore("integer_division")
	func exec_map_part(pairs: Array) -> Dictionary:
		var res := {}
		for i in pairs.size() / 2:
			var k = exec_item(pairs[2 * i])
			var v = exec_item(pairs[2 * i + 1])
			res[k] = v
		return res

class Stream:
	var raw: String
	var vlen: int
	
	func _init(praw: String) -> void:
		raw = praw
		vlen = praw.length()
	
	func ref(offset: int) -> Variant:
		@warning_ignore("incompatible_ternary")
		return raw[offset] if offset < vlen else null

class Parser:
	var stream: Stream
	var offset: int
	var result := []
	
	func _init(pstream: Stream, poffset := 0) -> void:
		stream = pstream
		offset = poffset
	
	func clone() -> Parser:
		var np := Parser.new(stream, offset)
		np.result = result.duplicate()
		return np
	
	func fork() -> Parser:
		return Parser.new(stream, offset)
	
	func push(type: StringName, data: Variant, prange = null) -> void:
		if prange != null:
			result.append([type, data, prange])
		else:
			result.append([type, data])
	
	func r_root() -> bool:
		var np := fork()
		while np.r_blank() and np.r_item(): pass
		if np.offset == np.stream.vlen:
			offset = np.offset
			result = np.result
			return true
		else:
			return false
	
	var _cs_blank := "\u0009\u000B\u000C\u0020\u00A0\u000A\u000D\u2028\u2029"
	
	func r_blank() -> bool:
		while r_whitespace() and r_comment(): pass
		return true
	
	func r_comment() -> bool:
		if stream.ref(offset) == ';':
			offset += 1
			var c = stream.ref(offset)
			while c != null and c != '\n':
				offset += 1
				c = stream.ref(offset)
			return true
		return false
	
	func r_whitespace() -> bool:
		var c = stream.ref(offset)
		while c != null and _cs_blank.contains(stream.ref(offset)):
			offset += 1
			c = stream.ref(offset)
		return true
	
	var _cs_n_token_head := "&()[]{}$#\"'-"
	var _cs_n_token_body := "()[]{}\"'"
	
	func r_token() -> bool:
		var poffset := offset
		var token := []
		var c = stream.ref(offset)
		if c != null and not _cs_blank.contains(c) and not _cs_n_token_head.contains(c) and not _cs_number.contains(c):
			token.append(c)
			offset += 1
			c = stream.ref(offset)
			while c != null and not _cs_blank.contains(c) and not _cs_n_token_body.contains(c):
				token.append(c)
				offset += 1
				c = stream.ref(offset)
			push(&"token", StringName(''.join(token)), [poffset, offset])
			return true
		return false
	
	func r_keyword() -> bool:
		var poffset := offset
		var keyword := []
		var c = stream.ref(offset)
		if c == '&':
			offset += 1
			c = stream.ref(offset)
			while c != null and not _cs_blank.contains(c) and not _cs_n_token_body.contains(c):
				keyword.append(c)
				offset += 1
				c = stream.ref(offset)
			if keyword.size() > 0:
				push(&"keyword", StringName(''.join(keyword)))
				return true
			else:
				offset = poffset
		return false
	
	func r_string() -> bool:
		var poffset := offset
		var string := []
		var c = stream.ref(offset)
		if c == '"':
			offset += 1
			c = stream.ref(offset)
			while true:
				match c:
					'"':
						offset += 1
						push(&"string", ''.join(string))
						return true
					'\\':
						var nc = stream.ref(offset + 1)
						if nc != null:
							string.append(((c + nc) as String).c_unescape())
							offset += 2
						else:
							offset = poffset
							return false
					null:
						offset = poffset
						return false
					_:
						string.append(c)
						offset += 1
				c = stream.ref(offset)
		return false
	
	var _cs_number := "0123456789.-"
	
	func r_number() -> bool:
		var num := []
		var c = stream.ref(offset)
		while c != null and _cs_number.contains(c):
			num.append(c)
			offset += 1
			c = stream.ref(offset)
		if num.size() > 0:
			push(&"number", ''.join(num).to_float())
			return true
		else:
			return false
	
	func r_bool() -> bool:
		if stream.ref(offset) == '#':
			var nc = stream.ref(offset + 1)
			match nc:
				't':
					offset += 2
					push(&"bool", true)
					return true
				'f':
					offset += 2
					push(&"bool", false)
					return true
				_:
					return false
		return false
	
	func r_value() -> bool:
		if r_number() \
		or r_bool() \
		or r_keyword() \
		or r_string():
			return true
		return false
	
	func r_list() -> bool:
		var poffset := offset
		var np := fork()
		if np.stream.ref(np.offset) == '(':
			np.offset += 1
			while np.r_blank() and np.r_item(): pass
			np.r_blank()
			if np.stream.ref(np.offset) == ')':
				np.offset += 1
				offset = np.offset
				push(&"list", np.result, [poffset, offset])
				return true
		return false
	
	func r_array() -> bool:
		var np := fork()
		if np.stream.ref(np.offset) == '[':
			np.offset += 1
			while np.r_blank() and np.r_item(): pass
			np.r_blank()
			if np.stream.ref(np.offset) == ']':
				np.offset += 1
				offset = np.offset
				push(&"array", np.result)
				return true
		return false
	
	func r_map() -> bool:
		var np := fork()
		if np.stream.ref(np.offset) == '{':
			np.offset += 1
			while np.r_blank() and (np.r_keyword() or np.r_string()) and np.r_blank() and np.r_item(): pass
			np.r_blank()
			if np.stream.ref(np.offset) == '}':
				if np.result.size() % 2 == 0:
					np.offset += 1
					offset = np.offset
					push(&"map", np.result)
					return true
		return false
	
	func r_set() -> bool:
		if r_list() \
		or r_array() \
		or r_map():
			return true
		return false
	
	func r_item() -> bool:
		if r_value() \
		or r_set() \
		or r_token():
			return true
		return false
