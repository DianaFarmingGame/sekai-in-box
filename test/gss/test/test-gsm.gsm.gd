# 文件名 xxx.gsm.gd

# 此处为 GDScript 环境

# (可选) 添加此变量以在 GDScript 环境中使用 GSS 的执行上下文
var gtx: LisperContext

func hello(pname):
	await gtx.eval(' echo ("say hello from GDScript!") ')
	return "say hello to " + pname

var vname = "GDScript!"

# 固定句式
func gsm(): return ['

; 此处为 GSS 环境

; 从 GD 环境获取函数并在 GSS 内定义
fn (hello :gd ', hello ,')

; 对于一般的使用情况, 也可以直接免去包装, 上面的代码可以替换为这种写法
var (hello ', hello ,')

; 从 GD 环境获取变量并在 GSS 内定义
var (name ', vname ,')

; 直接使用 GD 的 Lambda 函数
fn (:gd ', func (pstr): print(gtx.print_head + pstr) ,') (hello (name))

; 对应的免包装写法
', func (pstr): print(gtx.print_head + pstr) ,' (hello (name))

; 获取当前模块的路径和父目录
echo (*mod-path*)
echo (*mod-dir*)

; 获取当前模块对应的 Godot 对象 (相当于 GDScript 内的 self)
echo (self)

; 使用 Lisper 调试器对断点进行分析
var (outer-var :const [1 2 3 4 5 6 7 8 9 0])
fn (test [arg]
	switch (arg
		"yes" echo ("all right!")
		"oops" block (
			!break ()
			failed-call (arg)
		)
	)
)
test ("oops")

'] # 固定句式
