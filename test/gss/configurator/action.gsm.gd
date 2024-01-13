func gsm():
	return ['


defvar(data csv/map-let(+(*config_base* "action.csv")
	[ID 类型 发起者 数据 跳转表 检测物品] {
		ID ID
		类型 keyword(类型)
		发起者 keyword(发起者)
		数据 数据
		跳转表 =>(跳转表
				string/split("\n")
				array/filter(func([l] !=(l "")))
				array/map(func([l] =>(l
					string/split(":")
					array/map(string/trim)
					func([pair] @=(pair 1 keyword(@(pair 1))) pair)()))))
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
								template(do(src check_bag_item item :eval @(opt &数据)))
							#t
								template(echo("unsupport dialog type:" :eval @(opt &类型)))
							))))))
			; raw/echo(expr)
			dbs/define(["行为" @(record &ID) eval(expr)])
			))
	))

']

func item_judge_t(item_ary: String):
	return item_ary.split(" ")