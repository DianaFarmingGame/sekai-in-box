# name： 	String
# count:	float
# recover:	bool

func gsm():
	return ["""

defunc(produce :gd """, produce,""")
defunc(final :gd """, final,""")

csv/map-let(+(*config_base* "shop.csv")
	[NPCID 商品名称 商品数量 是否可恢复]
	produce(*sekai* {
		ID		keyword(NPCID)
		name	商品名称
		count	商品数量
		recover	是否可恢复
	})
)

final(*sekai*)

"""]

var res_id := &""
var res_map := {}

func produce(sekai: Sekai, o: Dictionary):
	var name = o["name"]
	var count = o["count"]
	var recover = o["recover"]
	var id = o["ID"]

	if id != "":
		if res_map.size() > 0:
			sekai.dbs_define("商店", res_id, res_map)
		
		res_id = id
		res_map = {}
	
	res_map[name] = {"count": count, "recover": recover}


func final(sekai: Sekai):
	if res_map.size() > 0:
		sekai.dbs_define("商店", res_id, res_map)

	


	
