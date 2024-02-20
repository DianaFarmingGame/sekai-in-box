func gsm(): return ['

var(judge_bag_data_t ', judge_bag_data_t,')
var(jump_t_dailog ', jump_t_dailog,')
var(jump_t_non_dailog ', jump_t_non_dailog,')
var(change_desc_data_t ', change_desc_data_t,')
var(change_data_data_t ', change_data_data_t,')
var(exchange_item_data_t ', exchange_item_data_t,')
var(item2mono :const ', func (sekai: Sekai, items: Dictionary) -> Array:
	var res = []

	for item in items:
		var item_id = item
		var item_num = items[item]

		var item_mono = sekai.make_mono(item_id, {&"props": {&"stack_count": item_num}})

		res.append(item_mono)

	return res
,')

var(add_to_talking_pool :const ', func(ctrl: SekaiControl, gikou: Mono, mono_id: Variant) -> Mono:
	var ctx := ctrl.context

	if mono_id is Mono:
		var mono = mono_id
		mono_id = mono.define.id
		await gikou.applymRSU(ctx, &"db/setp", [&"talking_pool", mono_id, mono])
		return mono
		
	if await gikou.callmRSU(ctx, &"db/has", mono_id):
		return await gikou.applymRSU(ctx, &"db/getp", [&"talking_pool", mono_id])

	var hako := ctrl.hako
	var mono = await hako.callmRSU(ctx, &"container/get_by_ref_id", mono_id)


	await gikou.applymRSU(ctx, &"db/setp", [&"talking_pool", mono_id, mono])
	
	return mono
,')

var(clean_talking_pool :const ', func(ctrl: SekaiControl, gikou: Mono):
	var ctx := ctrl.context
	await gikou.callm(ctx, &"db/clean", &"talking_pool")
,')

var(random_choose :const ', func(ary: Array) -> Variant:
	var idx = randi() % ary.size()
	return ary[idx]
,')

var(get_mono :const ', func(ctrl: SekaiControl, gikou: Mono, mono_id: Variant) -> Mono:
	var ctx := ctrl.context

	if mono_id is Mono:
		return mono_id
		
	if await gikou.callmRSU(ctx, &"db/has", mono_id):
		return await gikou.applymRSU(ctx, &"db/getp", mono_id)

	var hako := ctrl.hako
	var mono = await hako.callmRSU(ctx, &"container/get_by_ref_id", mono_id)

	return mono
,')

defvar(data csv/map-let(+(*config_base* "action.csv")
	[ID 类型 发起者 数据 跳转表] {
		ID ID
		类型 keyword(类型)
		发起者 keyword(发起者)
		数据 switch(类型
			"修改任务描述" change_desc_data_t(数据)
			"修改变量" change_data_data_t(数据)
			"物品交换" exchange_item_data_t(数据)
			"背包检测" judge_bag_data_t(数据)
			#t 数据)
		跳转表 switch(类型
			"选择" jump_t_dailog(跳转表)
			"背包检测" jump_t_non_dailog(跳转表)
			"变量检测" jump_t_non_dailog(跳转表)
			"物品交换" jump_t_non_dailog(跳转表)
			"随机多选一" jump_t_non_dailog(跳转表)
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
			var (ary array/concat(ary [{类型 keyword("end")}]))
			defvar(expr template
				(func([ctrl src tar sets]
					add_to_talking_pool(ctrl gikou tar)
					:expand :raw
					array/map(ary func([opt]
						switch(@(opt &类型)
							&对话
								template(block(
									var (talker add_to_talking_pool(ctrl gikou :eval @(opt &发起者)))
									do(target msg_dialog/put ctrl {
										name #(talker . name)
										avatar #((talker . asserts) @ "avatar")
										text :eval @(opt &数据)
									})
								))
							&旁白
								template(do(target msg_dialog/put ctrl {
									name :eval @(opt &发起者)
									text :eval @(opt &数据)
								}))
							&选择
								template
									(do(target choose_dialog/switch ctrl {title: :eval @(opt &数据)} 
										:expand :raw 
										array/flat(array/map(@(opt &跳转表) func([item]
											[
												template(eval(do(gikou db/val_replace string->raw(:eval @(item 2)))))
												raw<-(@(item 0))
												template(do(this action/call :eval @(item 1) ctrl src tar sets))
											]
										)))
									))
							&背包检测
								template(if(>=(do(src container/count_by_ref_id :eval @(@(opt &数据) 0)) :eval @(@(opt &数据) 1))
									if(==(:eval @(@(opt &跳转表) 0) "pass")
										echo("[lisp] bag check" :eval @(@(opt &数据) 0) ":" :eval @(@(opt &数据) 1) "success")
										do(this action/call :eval @(@(opt &跳转表) 0) ctrl src tar sets)
									)
									do(this action/call :eval @(@(opt &跳转表) 1) ctrl src tar sets)
								))
							&开启任务
								template(do(gikou taskm/activate keyword(:eval @(opt &数据))))
							&完成任务
								template(do(gikou task/deactivate keyword(:eval @(opt &数据))))
							&修改变量
								template(do(gikou db/set :eval keyword(@(@(opt &数据) 0)) eval(do(gikou db/val_replace string->raw(:eval @(@(opt &数据) 1)))) keyword("vals")))
							&变量检测
								template(if(eval(do(gikou db/val_replace string->raw(:eval @(opt &数据))))
									if(==(:eval @(@(opt &跳转表) 0) "pass")
										echo("[lisp] val check" :eval @(opt &数据) "success")
										do(this action/call :eval @(@(opt &跳转表) 0) ctrl src tar sets)
									)
									do(this action/call :eval @(@(opt &跳转表) 1) ctrl src tar sets)
								))
							&物品交换
								template(switch(do(src exchange_item :eval @(@(opt &数据) 0) :eval @(@(opt &数据) 1))
									&0
										if (==(:eval @(@(opt &跳转表) 0) "pass")
											echo("[lisp] exchange item +: " :eval @(@(opt &数据) 0) "-:" :eval @(@(opt &数据) 1) "success")
											do(this action/call :eval @(@(opt &跳转表) 0) ctrl src tar sets)
										)
									&1
										if (==(:eval @(@(opt &跳转表) 1) "pass")
											echo("[lisp] exchange item +: " :eval @(@(opt &数据) 0) "-:" :eval @(@(opt &数据) 1) "send fail")
											do(this action/call :eval @(@(opt &跳转表) 1) ctrl src tar sets)
										)
									&2
										if (==(:eval @(@(opt &跳转表) 2) "pass")
											echo("[lisp] exchange item +: " :eval @(@(opt &数据) 0) "-:" :eval @(@(opt &数据) 1) "receive fail")
											do(this action/call :eval @(@(opt &跳转表) 2) ctrl src tar sets)
										)
								))
							&行为覆盖
								template(do(this action/set keyword("primary") :eval @(opt &数据)))
							&随机多选一
								template(do(this action/call random_choose(:eval @(opt &跳转表)) ctrl src tar sets))
							&走向
								template(block(
									var (starter add_to_talking_pool(ctrl gikou :eval @(opt &发起者)))
									var (end add_to_talking_pool(ctrl gikou :eval @(opt &数据)))
									go
										(do(starter move/to end))
								))
							&end
								template(clean_talking_pool(ctrl gikou))
							#t
								template(echo("unsupport dialog type:" :eval @(opt &类型)))
							))))))
									
			do (db db/set keyword(@(record &ID)) eval(expr) keyword("actions"))
			))
	))

']


func judge_bag_data_t(item: String):
	var res = Array(item.split(":"))
	res[1] = int(res[1])
	return res

func jump_t_dailog(table: String) -> Array:
	var table_ary = table.split("\n", false)

	var res = []
	for item in table_ary:
		var item_ary = item.split(":")
		if item_ary.size() == 3:
			res.append([item_ary[0].strip_edges(), StringName(item_ary[1].strip_edges()), item_ary[2].strip_edges()])
		else:
			res.append([item_ary[0].strip_edges(), StringName(item_ary[1].strip_edges()), "#t"])
	return res

func jump_t_non_dailog(table: String) -> Array:
	var res := Array(table.split("\n"))

	for i in range(res.size()):
		res[i] = StringName(res[i].strip_edges())

	return res

func change_desc_data_t(data: String):
	var res = data.split(":")
	res[0].strip_edges()

	return res

func change_data_data_t(data: String):
	var res = data.split(":")
	res[0].strip_edges()

	return res

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


