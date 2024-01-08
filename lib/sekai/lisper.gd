class_name Lisper extends Object

static func tokenize(expr: String) -> Variant:
	var parser := GispParser.make(expr)
	if parser.parse():
		return parser.get_result()
	else:
		return null

static func is_node(node: Variant) -> bool: return node is Array and node.size() > 0 and node[0] is TType

static func List(nodes: Array) -> Array: return [TType.LIST, nodes]

static func Token(name: StringName) -> Array: return [TType.TOKEN, name]

static func Keyword(name: StringName) -> Array: return [TType.KEYWORD, name]

static func String(content: String) -> Array: return [TType.STRING, content]

static func Bool(value: bool) -> Array: return [TType.BOOL, value]

static func Number(value: float) -> Array: return [TType.NUMBER, value]

static func Array(nodes: Array) -> Array: return [TType.ARRAY, nodes]

static func Raw(value: Variant) -> Array: return [TType.RAW, value]

static func is_raw(node: Variant) -> bool: return is_node(node) and TType.RAW == node[0]

static func RawOverride(value: Variant) -> Array: return [TType.RAW_OVERRIDE, value]

static func is_raw_override(node: Variant) -> bool: return is_node(node) and TType.RAW_OVERRIDE == node[0]

static func Call(name: StringName, tails = null) -> Array:
	var body := [Token(name)]
	if tails != null: for tail in tails:
		body.append_array(tail)
	return List(body)

static func Func(args: Array[StringName], body: Array) -> Array:
	var vbody := [[
		Lisper.Array(args.map(func (token): return Lisper.Token(token))),
	]]
	vbody.append_array(body)
	return Lisper.Call(&"func", vbody)

static func FnGDRaw(handle: Callable) -> Array: return [FnType.GD_RAW, handle]

static func FnGDMacro(handle: Callable) -> Array: return [FnType.GD_MACRO, handle]

static func FnGDCall(handle: Callable) -> Array: return [FnType.GD_CALL, handle]

static func FnGDCallP(handle: Callable) -> Array: return [FnType.GD_CALL_PURE, handle]

static func FnGDApply(handle: Callable) -> Array: return [FnType.GD_APPLY, handle]

static func FnGDApplyP(handle: Callable) -> Array: return [FnType.GD_APPLY_PURE, handle]

static func count_last_len(pstr: String, indent: int) -> int:
	var slices := pstr.split('\n')
	if slices.size() > 1:
		return slices[-1].length()
	else:
		return indent + slices[0].length()

static func stringify_raw(data: Variant, indent := 0) -> String:
	if data is Dictionary:
		var res := ['{']
		for k in data.keys():
			var v = data[k]
			res.append('\n' + ''.lpad(indent + 4, ' ') + k + ': ' + Lisper.stringify_raw(v, indent + 4))
		res.append('\n' + ''.lpad(indent, ' ') + '}')
		return ''.join(res)
	if data is Array:
		return '[' + ' '.join(data.map(func (n): return Lisper.stringify_raw(n, indent))) + ']'
	if data is String:
		var slices := (data as String).split('\n')
		return '"' + slices[0] + ''.join(Array(slices.slice(1)).map(func (s): return '\n' + ''.lpad(indent + 1, ' ') + s)) + '"'
	return var_to_str(data)

static func stringify(node: Array, indent := 0) -> String:
	match node[0]:
		TType.TOKEN:
			return str(node[1])
		TType.NUMBER:
			return str(node[1])
		TType.BOOL:
			return "#t" if node[1] else "#f"
		TType.KEYWORD:
			return str('&', node[1])
		TType.STRING:
			var slices := (node[1] as String).split('\n')
			return '"' + slices[0] + ''.join(Array(slices.slice(1)).map(func (s): return '\n' + ''.lpad(indent + 1, ' ') + s)) + '"'
		TType.LIST:
			var head_str := Lisper.stringify(node[1][0], indent)
			indent = count_last_len(head_str, indent) + 2
			var body := node[1].slice(1) as Array
			if body.size() <= 1:
				return head_str + ' (' + ' '.join(body.map(func (n): return Lisper.stringify(n, indent))) + ')'
			return head_str + ' (' + \
			Lisper.stringify(body[0], indent) + \
			''.join(body.slice(1).map(func (n): return '\n' + ''.lpad(indent, ' ') + Lisper.stringify(n, indent))) + ')'
		TType.ARRAY:
			return '[' + ' '.join(node[1].map(func (n): return Lisper.stringify(n, indent))) + ']'
		TType.MAP:
			var res := ['{']
			var key := true
			var idn := indent
			for n in node[1]:
				if key:
					var vstr := '\n' + ''.lpad(indent + 4, ' ') + Lisper.stringify(n, indent + 4)
					idn = count_last_len(vstr, indent) + 1
					res.append(vstr)
				else:
					res.append(' ' + Lisper.stringify(n, idn))
				key = not key
			res.append('\n' + ''.lpad(indent, ' ') + '}')
			return ''.join(res)
		TType.RAW:
			var value = node[1]
			return '<' + Lisper.stringify_raw(value, indent + 1) + '>'
	push_error("unknown typed node: ", node)
	return "<unknown>"

static func stringifys(body: Array) -> String:
	return ' '.join(body.map(Lisper.stringify))

static func test_parser() -> void:
	print(Lisper.tokenize("1 0 .5 10 204.2 3.30"))
	print(Lisper.tokenize("#t #f#t"))
	print(Lisper.tokenize("\"string\" \"quote\\\"ed\"\"nested\""))
	print(Lisper.tokenize("&keyword &+1 &&"))
	print(Lisper.tokenize("token t$&.#"))
	print(Lisper.tokenize("list(tail) nested(list(1 2 3))"))
	print(Lisper.tokenize("[] [array 1 2 3] [nested [1 2 3]]"))
	print(Lisper.tokenize("{} {&map [1 2 3] &nested {&id &123}}"))
	print(Lisper.tokenize("; comment\n token ; another comment"))
	print(Lisper.tokenize("#;[ skiper comment ]"))

## Token类型
enum TType {
	TOKEN,
	NUMBER,
	BOOL,
	KEYWORD,
	STRING,
	LIST,
	ARRAY,
	MAP,
	
	RAW,
	RAW_OVERRIDE,
}

## 函数类型
enum FnType {
	## Raw型Callable，首位传入执行上下文
	## 慎用: 实现较复杂，且需要手动维持词法作用域
	GD_RAW,
	## Macro型Callable
	GD_MACRO,
	## 一般Callable
	GD_CALL,
	## 一般Callable(纯函数，输出与输入绝对对应且无副作用)
	GD_CALL_PURE,
	## 一般Callable，传入参数为数组形式，首位传入执行上下文
	GD_APPLY,
	## 一般Callable，传入参数为数组形式，首位传入执行上下文(纯函数，输出与输入绝对对应且无副作用)
	GD_APPLY_PURE,
	
	LP_CALL,
}

## 变量标记
##
## 对于纯函数类型，使用两个标志会启用全部优化
enum VarFlag {
	## 常量，定义不可修改但可以被覆盖
	CONST,
	## 定点，定义可以修改但不可被掩盖
	FIX,
}
