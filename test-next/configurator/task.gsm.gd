func gsm():
	return ['

var(produce ', produce,')
var(final ', final,')

csv/map-let(+(*config_base* "task.csv")
	[ID 组 任务名 任务描述 完成条件 完成行为 需求类型 需求描述 需求数据]
	produce(sekai {
		id				keyword(ID)
		group			组
		name			任务名
		desc			任务描述
		finish			keyword(完成条件)
		action			keyword(完成行为)
		require_type	需求类型
		require_desc	需求描述
		require_data	需求数据
	})

final(sekai)
	
)
']


var res_map := {}

func produce(db, o: Dictionary):
	if o["id"] != "":
		if res_map.size() > 0:
			sekai.dbs_define("任务", res_map["id"], res_map)
			
		res_map = o
		res_map.erase("require_type")
		res_map.erase("require_desc")
		res_map.erase("require_data")
		res_map["require"] = []

	res_map["require"].append({
		"type": o["require_type"],
		"desc": o["require_desc"],
		"data": o["require_data"]
	})
	

func final(sekai: Sekai):
	if res_map.size() > 0:
		sekai.dbs_define("任务", res_map["id"], res_map)

	
