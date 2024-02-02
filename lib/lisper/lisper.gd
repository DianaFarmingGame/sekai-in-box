class_name Lisper

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

static func is_array(node: Variant) -> bool: return is_node(node) and TType.ARRAY == node[0]

static func Map(nodes: Array) -> Array: return [TType.MAP, nodes]

static func is_map(node: Variant) -> bool: return is_node(node) and TType.MAP == node[0]

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

class Function:
	var type: FnType
	var data: Variant
	func _init(ptype: FnType = FnType.GD_CALL, pdata: Variant = null) -> void:
		type = ptype
		data = pdata

static func FnGDRaw(handle: Callable) -> Function: return Function.new(FnType.GD_RAW, handle)

static func FnGDMacro(handle: Callable) -> Function: return Function.new(FnType.GD_MACRO, handle)

static func FnGDCall(handle: Callable) -> Function: return Function.new(FnType.GD_CALL, handle)

static func FnGDCallP(handle: Callable) -> Function: return Function.new(FnType.GD_CALL_PURE, handle)

static func FnGDApply(handle: Callable) -> Function: return Function.new(FnType.GD_APPLY, handle)

static func FnGDApplyP(handle: Callable) -> Function: return Function.new(FnType.GD_APPLY_PURE, handle)

static func fn_gd_get_handle(handle: Variant) -> Callable: return handle.data if handle is Function else handle

static func FnLPCall(args: Array, body: Array) -> Function: return Function.new(FnType.LP_CALL, [args, body])

static func FnLPCallP(args: Array, body: Array) -> Function: return Function.new(FnType.LP_CALL_PURE, [args, body])

static func fn_lp_get_args(handle: Function) -> Array: return handle.data[0]

static func fn_lp_get_body(handle: Function) -> Array: return handle.data[1]

static func fn_get_type(handle: Variant) -> Variant: return FnType.GD_CALL if handle is Callable else handle.type if handle is Function else null

static func is_fn(handle: Variant) -> bool: return handle is Callable or handle is Function

static func is_same_approx(a: Variant, b: Variant) -> bool:
	return is_same(a, b) \
	or (typeof(a) == TYPE_INT \
		and typeof(b) == TYPE_FLOAT \
		and a == b) \
	or (typeof(a) == TYPE_FLOAT \
		and typeof(b) == TYPE_INT \
		and a == b)

static func resolve_path(mod_dir: Variant, path: String) -> String:
	if path.is_relative_path() and mod_dir != null:
		path = (mod_dir as String).path_join(path)
	return path

static func count_last_len(pstr: String, indent: int) -> int:
	var slices := pstr.split('\n')
	if slices.size() > 1:
		return slices[-1].length()
	else:
		return indent + slices[0].length()

static func stringify_flatten(tag: Array) -> String:
	return ''.join(tag.slice(1).map(func (t):
		if t is String:
			return t
		else:
			return Lisper.stringify_flatten(t)))

static func stringify_find_pos(tag: Array, column: int, line := 0) -> Variant:
	var rstr := Lisper.stringify_flatten(tag)
	var last_nl := -1
	while line > 0:
		last_nl = rstr.find('\n', last_nl + 1)
		line -= 1
	column += last_nl + 1
	var res = _find_pos(0, tag, column)
	if res != null:
		return [res[0], res.slice(1), Lisper._cvt_poses(rstr, res.slice(1))]
	else:
		return null

static func _find_pos(soffset: int, tag: Array, tarcol: int) -> Variant:
	var coffset := soffset
	for t in tag.slice(1):
		#if coffset > tarcol: break;
		if t is String:
			coffset += t.length()
		else:
			var r = Lisper._find_pos(coffset, t, tarcol)
			if r != null: return r
			coffset += Lisper.stringify_flatten(t).length()
	var eoffset := soffset + Lisper.stringify_flatten(tag).length()
	if soffset <= tarcol and eoffset >= tarcol: return [tag[0], soffset, eoffset]
	return null

static func _cvt_poses(string: String, poses: Array) -> Array:
	return poses.map(func (m):
		var slice := string.substr(0, m)
		var line := slice.count('\n')
		var column := slice.length() - slice.rfind('\n') - 1
		return [line, column])

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
	ctx.push_module_meta({
		&"*mod-path*": path,
		&"*mod-dir*": path.get_base_dir(),
		&"self": null,
	})
	await ctx.eval(gss)
	ctx.pop_module_meta()

static func exec_gsm(ctx: LisperContext, gsm: Object) -> void:
	if gsm.has_method(&"new"): gsm = gsm.new()
	var path = gsm.get_script().resource_path
	ctx.push_module_meta({
		&"*mod-path*": path,
		&"*mod-dir*": path.get_base_dir(),
		&"self": gsm,
	})
	var need_gtx := gsm.get_property_list().any(func (opt): return opt[&"name"] == &"gtx")
	if need_gtx == true: gsm.gtx = ctx
	if gsm.has_method(&"gsm_init"): await gsm.gsm_init(ctx)
	if gsm.has_method(&"gsm"): 
		var content := await gsm.gsm() as Array
		await ctx.meval(content)
	if gsm.has_method(&"gsm_inited"): await gsm.gsm_inited(ctx)
	ctx.pop_module_meta()

static func test_parser() -> void:
	print(Lisper.tokenize("1 0 10 204.2 3.30"))
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
