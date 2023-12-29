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

static func FuncGDRaw(handle: Callable) -> Array: return [FnType.GD_RAW, handle]

static func FuncGDRawPure(handle: Callable) -> Array: return [FnType.GD_RAW_PURE, handle]

static func FuncGDCall(handle: Callable) -> Array: return [FnType.GD_CALL, handle]

static func FuncGDCallPure(handle: Callable) -> Array: return [FnType.GD_CALL_PURE, handle]

static func FuncGDMacro(handle: Callable) -> Array: return [FnType.GD_MACRO, handle]

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
