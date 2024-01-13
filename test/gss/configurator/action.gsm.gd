func gsm():
	return ['

var(item_judge_t ', item_judge_t,')
var(jump_t_dailog ', jump_t_dailog,')
var(jump_t_non_dailog ', jump_t_non_dailog,')

defvar(data csv/map-let(+(*config_base* "action.csv")
	[ID 类型 发起者 数据 跳转表] {
		ID ID
		类型 keyword(类型)
		发起者 keyword(发起者)
		数据 数据
		跳转表 switch(类型
			"选择" jump_t_dailog(跳转表)
			"背包检测" jump_t_non_dailog(跳转表)
			#t "")
	}))
!debug()

array/for(data func([i record]
	if(and(!=(@(record &类型) &)
			 !=(@(record &ID) ""))
		block
			(defvar(cur-i i)
			loop*(skip escape
				if(not(and(<(cur-i array/size(data))
							  =>(data @(cur-i) @(&类型) !=(&))))
					escape())
				+1(cur-i))
			defvar(ary array/slice(data i cur-i))
			defvar(expr template
				(func([sekai this src]
					:expand :raw
					array/map(ary func([opt]
						switch(@(opt &类型)
							&对话 switch(@(opt &发起者)
								&主 template(do(src say_to this :eval @(opt &数据)))
								&宾 template(do(this say_to src :eval @(opt &数据))))
							&旁白
								template(do(src show_aside :eval @(opt &数据)))
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
							#t
								template(echo("unsupport dialog type:" :eval @(opt &类型)))
							))))))
			; raw/echo(expr)
			dbs/define(["行为" @(record &ID) eval(expr)])
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

