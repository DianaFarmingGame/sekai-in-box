class_name Lisper extends Object

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

static func Raw(value: Variant) -> Array: return [TType.RAW, value]

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

static func FuncGDRaw(handle: Callable) -> Array: return [FnType.GD_RAW, handle]

static func FuncGDRawPure(handle: Callable) -> Array: return [FnType.GD_RAW_PURE, handle]

static func FuncGDCall(handle: Callable) -> Array: return [FnType.GD_CALL, handle]

static func FuncGDCallPure(handle: Callable) -> Array: return [FnType.GD_CALL_PURE, handle]

static func FuncGDMacro(handle: Callable) -> Array: return [FnType.GD_MACRO, handle]

static func stringify(node: Array, indent := 0) -> String:
	match node[0]:
		TType.TOKEN:
			return str(node[1])
		TType.NUMBER:
			return str(node[1])
		TType.BOOL:
			match node[1]:
				true: return "#t"
				false: return "#f"
		TType.KEYWORD:
			return str('&', node[1])
		TType.STRING:
			return str('"', (node[1] as String).c_escape(), '"')
		TType.LIST:
			var body = node[1]
			if body.size() <= 2:
				return '(' + ' '.join(node[1].map(func (n): return Lisper.stringify(n, indent))) + ')'
			return '(' + \
			Lisper.stringify(body[0], indent) + ' ' + \
			Lisper.stringify(body[1], indent) + \
			''.join(body.slice(2).map(func (n): return '\n' + ''.lpad(indent+1, '\t') + Lisper.stringify(n, indent + 1))) + ')'
		TType.ARRAY:
			return '[' + ' '.join(node[1].map(func (n): return Lisper.stringify(n, indent))) + ']'
		TType.MAP:
			var res := ['{']
			var key := true
			for n in node[1]:
				if key:
					res.append('\n' + ''.lpad(indent+1, '\t'))
					res.append(Lisper.stringify(n, indent + 1))
				else:
					res.append(' ')
					res.append(Lisper.stringify(n, indent + 2))
				key = not key
			res.append('\n' + ''.lpad(indent, '\t') + '}')
			return ''.join(res)
		TType.RAW:
			return str(node[1])
	push_error("unknown typed node: ", node)
	return "<UNKNOWN>"

static func stringifys(body: Array) -> String:
	return ' '.join(body.map(Lisper.stringify))

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
}

## 函数类型
enum FnType {
	## 一般Callable
	GD_CALL,
	## 一般Callable(纯函数，输出与输入绝对对应且无副作用)
	GD_CALL_PURE,
	## Raw型Callable
	GD_RAW,
	## Raw型Callable(纯函数，输出与输入绝对对应且无副作用)
	GD_RAW_PURE,
	## Macro型Callable
	GD_MACRO,
	
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
