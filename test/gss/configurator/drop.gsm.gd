# {destoryID: [{itemID: stringName, countList: [int], probability: [float]}, ...]}

func gsm():
	return ["""

defunc (produce :gd """, produce,""")
defunc (number_t :gd """, number_t,""")
defunc (probability_t :gd """, probability_t,""")
defunc (final :gd """, final,""")

csv/map-let(+(*config_base* "drop.csv")
	[破坏方块 掉落 数量 概率]
	produce(*sekai* {
		destoryID 	keyword(破坏方块)
		itemID 		keyword(掉落)
		countList 	number_t(数量)
		probability probability_t(概率)
	})	
)

final(*sekai*)
	
"""]


var destory_id := ""
var drop_map := {}

func produce(sekai: Sekai, o: Dictionary):
	var item_id = o["itemID"]
	var count_list = o["countList"]
	var probability = o["probability"]

	assert(count_list.size() == probability.size(), "数量列表与概率列表数量不符")

	if o["destoryID"] != "":
		if drop_map.size() > 0:
			sekai.dbs_define("掉落", destory_id, drop_map)

		destory_id = o["destoryID"]
		drop_map = {}
	
	drop_map[item_id] = {"countList": count_list, "probability": probability}

func number_t(num: String) -> Array:
	var num_group := num.split(" ")
	var num_list := []
	for i in num_group:
		if i == "":
			continue
		var l := i.split("-")
		if l.size() == 1:
			num_list.append(l[0].to_int())
		else:
			for j in range(int(l[0]), int(l[1])+1):
				num_list.append(j)
	return num_list

func probability_t(prob: String) -> Array:
	var prob_group := prob.split(" ")
	var prob_list := []
	for i in prob_group:
		if i == "":
			continue
		prob_list.append(i.to_float())
	return prob_list

func final(sekai: Sekai):
	if drop_map.size() > 0:
		sekai.dbs_define("掉落", destory_id, drop_map)
