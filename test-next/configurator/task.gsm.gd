func gsm():
	return ['

var(produce ', produce,')
var(final ', final,')
var(reward_t ', reward_t,')

csv/map-let(+(*config_base* "task.csv")
	[ID 组 任务名 任务描述 完成条件 完成行为 任务奖励 需求类型 需求描述 需求数据]
	produce({
		id				keyword(ID)
		group			组
		name			任务名
		desc			任务描述
		finish			keyword(完成条件)
		next			keyword(完成行为)
		rewards			reward_t(任务奖励)

		require_type	需求类型
		require_desc	需求描述
		require_data	需求数据
	})

final()
	
)
']


# task format
# {
# 	"id": &"",
# 	"group": &"",
# 	"name": "",
# 	"desc": "",
# 	"next": &"",
# 	"finish": &"",
# 	"requirements: [{
# 		"type": TASK_TYPE,
# 		"data": {
#			"key": "",
#			"value": "",
#			"compare": COMPAIR_TYPE,
#		},
# 		"desc": "",
#	}],

var res_map := {}

func produce(o: Dictionary):
	if o["id"] != "":
		if res_map.size() > 0:
			res_map.erase("require_type")
			res_map.erase("require_desc")
			res_map.erase("require_data")

			task_init(res_map)

			sekai.db.applym(sekai.context, &"db/setp", [res_map[&"id"], res_map, &"task"]) 
			
			
		res_map = o
		res_map["requirements"] = []

	var required := {}

	var data

	if o["require_type"] == "背包检测":
		var datas = o["require_data"].split(":", false)
		required["mono_id"] = StringName(datas[0])
		data = datas[1].split(" ", false)
	else:
		data = o["require_data"].split(" ", false)
	
	required["key"] = data[0]
	required["value"] = float(data[2])
	var compare_str = data[1]

	if compare_str == "==":
		required["compare"] = COMPAIR_TYPE.EQUAL
	elif compare_str == "!=":
		required["compare"] = COMPAIR_TYPE.NOT_EQUAL
	elif compare_str == ">":
		required["compare"] = COMPAIR_TYPE.GREATER
	elif compare_str == "<":
		required["compare"] = COMPAIR_TYPE.LESS
	elif compare_str == ">=":
		required["compare"] = COMPAIR_TYPE.GREATER_EQUAL
	elif compare_str == "<=":
		required["compare"] = COMPAIR_TYPE.LESS_EQUAL
	else:
		push_error("[csv/task] unknown compare type: " + compare_str)
		return

	var type: int
	if o["require_type"] == "变量检测":
		type = REQUIREMENT_TYPE.WATCH_VAR
	elif o["require_type"] == "背包检测":
		type = REQUIREMENT_TYPE.BAG_CHECK
	elif o["require_type"] == "实体距离":
		type = REQUIREMENT_TYPE.DISTANCE_CHECK
	else:
		push_error("[csv/task] unknown requirement type: " + o["require_type"])
		return

	res_map["requirements"].append({
		"type": type,
		"desc": o["require_desc"],
		"data": required
	})
	

func final():
	if res_map.size() > 0:
		res_map.erase("require_type")
		res_map.erase("require_desc")
		res_map.erase("require_data")

		task_init(res_map)

		sekai.db.applym(sekai.context, &"db/set", [res_map["id"], res_map, &"task"]) 
	return

enum REQUIREMENT_TYPE {
	WATCH_VAR = 0,
	BAG_CHECK = 1,
	DISTANCE_CHECK = 2,
}

enum TASK_STATUS {
	NOT_START = 0,
	START = 1,
	COMPLETE = 2,
	FAIL = 3,
}

enum COMPAIR_TYPE {
	EQUAL = 0,
	NOT_EQUAL = 1,
	GREATER = 2,
	LESS = 3,
	GREATER_EQUAL = 4,
	LESS_EQUAL = 5,
}
	
func task_init(task: Dictionary):
	for k in task["requirements"]:
		k["current"] = 0
		k["complete"] = false

	task["status"] = TASK_STATUS.NOT_START

func reward_t(rewards_s: String) -> Dictionary:
	var rewards = rewards_s.split(" ", false)
	var reward := {}

	for i in rewards.size():
		var r = rewards[i].split(":", false)
		if r[0] == "金币":
			reward["money"] = int(r[1])
		else:
			reward[r[0]] = int(r[1])

	return reward
