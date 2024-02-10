func gsm(): return ['

var(item_judge_t ', item_judge_t,')
var(jump_t_dailog ', jump_t_dailog,')
var(jump_t_non_dailog ', jump_t_non_dailog,')
var(change_desc_data_t ', change_desc_data_t,')
var(change_data_data_t ', change_data_data_t,')
var(judge_data_data_t ', judge_data_data_t,')
var(exchange_item_data_t ', exchange_item_data_t,')
var(item2mono :const ', func (sekai: Sekai, items: Dictionary) -> Array:
	var res = []

	for item in items:
		var item_id = item
		var item_num = items[item]

		var item_define = sekai.get_define(item_id)
		var item_mono = sekai.make_mono_by_define(Mono, item_define, {&"props": {&"stack_count": item_num}})

		res.append(item_mono)

	return res
,')


defvar(data csv/map-let(+(*config_base* "action.csv")
	[ID 类型 发起者 数据 跳转表] {
		ID ID
		类型 keyword(类型)
		发起者 keyword(发起者)
		数据 switch(类型
			"修改任务描述" change_desc_data_t(数据)
			"修改变量" change_data_data_t(数据)
			"变量检测" judge_data_data_t(数据)
			"物品交换" exchange_item_data_t(数据)
			#t 数据)
		跳转表 switch(类型
			"选择" jump_t_dailog(跳转表)
			"背包检测" jump_t_non_dailog(跳转表)
			"变量检测" jump_t_non_dailog(跳转表)
			"物品交换" jump_t_non_dailog(跳转表)
			#t "")
	}))

array/for(data func([i record]
	if(and(!=(@(record &类型) &)
			 !=(@(record &ID) ""))
		block
			(defvar(cur-i i)
			loop*(skip escape
				if(not(and(<(cur-i array/size(data))
							  =>(data @(cur-i) @(&类型) !=(&))))
					escape())
				++(cur-i))
			defvar(ary array/slice(data i cur-i))
			defvar(expr template
				(func([sekai this src]
					:expand :raw
					array/map(ary func([opt]
						switch(@(opt &类型)
							&对话 switch(@(opt &发起者)
								&主 template(do(src say_to this :eval @(opt &数据)))
								&宾 template(do(this say_to src :eval @(opt &数据))))
							&选择
								template
									(do(src choose_single :eval @(opt &数据)
										:expand :raw
										array/flat(array/map(@(opt &跳转表) func([item]
											[raw<-(@(item 0)) template(do(this dialog_to src :eval @(item 1)))])))))
							&背包检测
								template(if(do(src check_bag_item :eval item_judge_t(@(opt &数据)))
									do(this dialog_to src :eval @(@(opt &跳转表) 0))
									do(this dialog_to src :eval @(@(opt &跳转表) 1))
								))
							&开启任务
								template(task/on(keyword(:eval @(opt &数据))))
							&关闭任务
								template(task/off(keyword(:eval @(opt &数据))))
							&修改任务描述
								template(task/desc(:eval keyword(@(@(opt &数据) 0)) :eval @(@(opt &数据) 1)))
							&修改变量
								template(data/set(:eval keyword(@(@(opt &数据) 0)) eval(dbr/raw(string->raw(:eval @(@(opt &数据) 1))))))
							&变量检测
								template(if(data/judge(string->raw(:eval @(opt &数据)))
									do(this dialog_to src :eval @(@(opt &跳转表) 0))
									do(this dialog_to src :eval @(@(opt &跳转表) 1))
								))
							&物品交换
								template(switch(do(src exchange_item item2mono(*sekai* :eval @(@(opt &数据) 0)) :eval @(@(opt &数据) 1))
										1 do(this dialog_to src :eval @(@(opt &跳转表) 0))
										2 do(this dialog_to src :eval @(@(opt &跳转表) 1))
								))
							&行为覆盖
								template(do(this change_interact :eval @(opt &数据)))
							#t
								template(echo("unsupport dialog type:" :eval @(opt &类型)))
							))))))

			do (db db/set keyword(@(record &ID)) eval(expr) keyword("行为"))
			))
	))

']

func item_judge_t(items: String):
	var item_dic = {}
	var item_ary = items.split(" ", false)
	
	for item in item_ary:
		item_dic[item.split(":")[0]] = int(item.split(":")[1])
	
	return item_dic

func jump_t_dailog(table: String) -> Array:
	var table_ary = table.split("\n", false)

	var res = []
	for item in table_ary:
		var item_ary = item.split(":")
		res.append([item_ary[0].strip_edges(), item_ary[1].strip_edges()])
	return res

func jump_t_non_dailog(table: String) -> Array:
	var res := table.split("\n")

	for i in range(res.size()):
		res[i] = res[i].strip_edges()

	return res

func change_desc_data_t(data: String):
	var res = data.split(":")
	res[0].strip_edges()

	return res

func change_data_data_t(data: String):
	var res = data.split(":")
	res[0].strip_edges()

	return res

func judge_data_data_t(data: String):
	var data_ary := data.split(":")
	for i in data_ary:
		i.strip_edges()

	var untokenize = ""
	untokenize += StringName(str(data_ary[1]))
	untokenize += "("
	untokenize += str(data_ary[0])
	untokenize += " "
	untokenize += str(data_ary[2])
	untokenize += ")"

	return untokenize

func exchange_item_data_t(data: String) -> Array:
	var this_item_input = {}
	var this_item_output = {}

	var data_ary = data.split("\n", false)
	var items = data_ary[0].split(" ", false)

	for item in items:
		var item_ary = item.split(":")

		if item_ary[0] == "+":
			this_item_input[item_ary[1]] = int(item_ary[2])
		elif item_ary[0] == "-":
			this_item_output[item_ary[1]] = int(item_ary[2])

	var res = [this_item_input, this_item_output]

	return res
