# 文件名 xxx.gsm.gd

# 此处为 GDScript 环境

# (可选) 添加此变量以在 GDScript 环境中使用 GSS 的执行上下文
var gtx: LisperContext

func hello(pname):
	await gtx.eval(""" echo ("say hello from GDScript!") """)
	return "say hello to " + pname

var vname = "GDScript!"

# 固定句式
func gsm(): return ["""

; 此处为 GSS 环境

; 从 GD 环境获取函数并在 GSS 内定义
defunc (hello :gd """, hello ,""")

; 从 GD 环境获取变量并在 GSS 内定义
defvar (name """, vname ,""")

; 直接使用 GD 的 Lambda 函数
func (:gd """, func (pstr): print(gtx.print_head + pstr) ,""")(hello(name))

; 获取当前模块的路径和父目录
echo (*mod-path*)
echo (*mod-dir*)

; 获取当前模块对应的 Godot 对象 (相当于 GDScript 内的 self)
echo (self)

"""] # 固定句式
