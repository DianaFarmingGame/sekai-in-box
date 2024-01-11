class_name Lisper extends Object

const ENABLE_DEBUGGER := true

static func tokenize(expr: String) -> Variant:
	var parser := GispParser.make(expr)
	if parser.parse():
		return parser.get_result()
	else:
		return null

static func is_node(node: Variant) -> bool: return node is Array and node.size() > 0 and node[0] is TType

static func List(nodes: Array) -> Array: return [TType.LIST, nodes]

static func Token(name: StringName) -> Array: return [TType.TOKEN, name]

static func is_flag(node: Variant) -> bool: return is_node(node) and TType.TOKEN == node[0] and node[1].begins_with(':')

static func Keyword(name: StringName) -> Array: return [TType.KEYWORD, name]

static func String(content: String) -> Array: return [TType.STRING, content]

static func Bool(value: bool) -> Array: return [TType.BOOL, value]

static func Number(value: float) -> Array: return [TType.NUMBER, value]

static func Array(nodes: Array) -> Array: return [TType.ARRAY, nodes]

static func Raw(value: Variant) -> Array: return [TType.RAW, value]

static func is_raw(node: Variant) -> bool: return is_node(node) and TType.RAW == node[0]

static func RawOverride(value: Variant) -> Array: return [TType.RAW_OVERRIDE, value]

static func is_raw_override(node: Variant) -> bool: return is_node(node) and TType.RAW_OVERRIDE == node[0]

static func apply(name: StringName, tails = null) -> Array:
	var body := [Token(name)]
	if tails != null: for tail in tails:
		body.append_array(tail)
	return List(body)

static func make_func(args: Array[StringName], body: Array) -> Array:
	var vbody := [[
		Lisper.Array(args.map(func (token): return Lisper.Token(token))),
	]]
	vbody.append_array(body)
	return Lisper.apply(&"func", vbody)

static var SymFunc := RefCounted.new()

static func FnGDRaw(handle: Callable) -> Array: return [Lisper.SymFunc, FnType.GD_RAW, handle]

static func FnGDMacro(handle: Callable) -> Array: return [Lisper.SymFunc, FnType.GD_MACRO, handle]

static func FnGDCall(handle: Callable) -> Array: return [Lisper.SymFunc, FnType.GD_CALL, handle]

static func FnGDCallP(handle: Callable) -> Array: return [Lisper.SymFunc, FnType.GD_CALL_PURE, handle]

static func FnGDApply(handle: Callable) -> Array: return [Lisper.SymFunc, FnType.GD_APPLY, handle]

static func FnGDApplyP(handle: Callable) -> Array: return [Lisper.SymFunc, FnType.GD_APPLY_PURE, handle]

static func fn_gd_get_handle(handle: Variant) -> Callable: return handle[2] if handle is Array else handle

static func FnLPCall(args: Array, body: Array) -> Array: return [Lisper.SymFunc, FnType.LP_CALL, args, body]

static func FnLPCallP(args: Array, body: Array) -> Array: return [Lisper.SymFunc, FnType.LP_CALL_PURE, args, body]

static func fn_lp_get_args(handle: Array) -> Array: return handle[2]

static func fn_lp_get_body(handle: Array) -> Array: return handle[3]

static func fn_get_type(handle: Variant) -> FnType: return handle[1] if handle is Array else FnType.GD_CALL

static func is_fn(handle: Variant) -> bool: return handle is Callable or (handle is Array and handle.size() > 0 and is_same(handle[0], Lisper.SymFunc))

static func count_last_len(pstr: String, indent: int) -> int:
	var slices := pstr.split('\n')
	if slices.size() > 1:
		return slices[-1].length()
	else:
		return indent + slices[0].length()

static func exec(ctx: LisperContext, path: String) -> void:
	if path.ends_with(".gss.txt"):
		var expr := FileAccess.get_file_as_string(path)
		if FileAccess.get_open_error() == OK:
			await Lisper.exec_gss(ctx, expr, path)
		else:
			push_error("failed to open gss file: ", path)
			printerr("failed to open gss file: ", path)
	elif path.ends_with(".gsm.gd"):
		await Lisper.exec_gsm(ctx, load(path))
	else:
		push_error("unknown gsx file: ", path)
		printerr("unknown gsx file: ", path)

static func exec_gss(ctx: LisperContext, gss: String, path: String) -> void:
	var pmod_path = ctx.get_var(&"*mod-path*")
	var pmod_dir = ctx.get_var(&"*mod-dir*")
	var pself = ctx.get_var(&"self")
	ctx.def_consts({
		&"*mod-path*": path,
		&"*mod-dir*": path.get_base_dir(),
		&"self": null,
	})
	await ctx.eval(gss)
	ctx.def_vars([], {
		&"*mod-path*": pmod_path,
		&"*mod-dir*": pmod_dir,
		&"self": pself,
	})

static func exec_gsm(ctx: LisperContext, gsm: Object) -> void:
	if gsm.has_method(&"new"): gsm = gsm.new()
	var path = gsm.get_script().resource_path
	var pmod_path = ctx.get_var(&"*mod-path*")
	var pmod_dir = ctx.get_var(&"*mod-dir*")
	var pself = ctx.get_var(&"self")
	ctx.def_consts({
		&"*mod-path*": path,
		&"*mod-dir*": path.get_base_dir(),
		&"self": gsm,
	})
	var need_gtx := gsm.get_property_list().any(func (opt): return opt[&"name"] == &"gtx")
	if need_gtx == true: gsm.gtx = ctx
	if gsm.has_method(&"gsm_init"): await gsm.gsm_init(ctx)
	var content := await gsm.gsm() as Array
	await ctx.meval(content)
	if gsm.has_method(&"gsm_inited"): await gsm.gsm_inited(ctx)
	ctx.def_vars([], {
		&"*mod-path*": pmod_path,
		&"*mod-dir*": pmod_dir,
		&"self": pself,
	})

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
