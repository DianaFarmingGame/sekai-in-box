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
	## Raw型Callable, 首位传入执行上下文
	## 慎用: 实现较复杂, 且需要手动维持词法作用域
	GD_RAW,
	## Macro型Callable
	GD_MACRO,
	## 一般Callable
	GD_CALL,
	## 一般Callable(纯函数, 输出与输入绝对对应且无副作用)
	GD_CALL_PURE,
	## 一般Callable, 传入参数为数组形式, 首位传入执行上下文
	GD_APPLY,
	## 一般Callable, 传入参数为数组形式, 首位传入执行上下文(纯函数, 输出与输入绝对对应且无副作用)
	GD_APPLY_PURE,
	
	## 一般Lisper函数
	LP_CALL,
	## 一般Lisper函数(纯函数, 输出与输入绝对对应且无副作用)
	LP_CALL_PURE,
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
