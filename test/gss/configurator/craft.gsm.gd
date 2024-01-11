# need [ {ID: int}, {ID: int}, ...]
# craft {ID: int}
# fuel {ID: int}
# time float
# desc String

func gsm():
	return ["""

defunc (craft2ID :gd """, craft2ID,""")
defunc (need_t :gd """, need_t,""")
defunc (craft_t :gd """, craft_t,""")
defunc (fuel_t :gd """, fuel_t,""")

csv/map-let (+ (*config_base* "craft.csv")
	[需求物品 合成物品 描述]
	dbs/define(["合成" craft2ID(合成物品) {
			need need_t(需求物品)
			craft craft_t(合成物品)
			desc 描述
		}
	])
)

csv/map-let (+ (*config_base* "enhance.csv")
	[需求物品 合成物品 描述]
	dbs/define (["附魔" craft2ID(合成物品) {
			need need_t(需求物品)
			craft craft_t(合成物品)
			desc 描述
		}
	])
)

csv/map-let (+ (*config_base* "cook.csv")
	[需求物品 合成物品 描述 消耗燃料 合成时间]
	dbs/define (["烹饪" craft2ID(合成物品) {
			need need_t(需求物品)
			craft craft_t(合成物品)

			fuel fuel_t(消耗燃料)
			time num(合成时间)

			desc 描述
		}
	])
)

"""]

func craft2ID(craft: String) -> String:
	return craft.split(":")[0]

func need_t(need: String) -> Dictionary:
	var item_list := need.split(" ")
	var craft_map := {}
	for item in item_list:
		if item == "":
			continue
		var item_info := item.split(":")
		craft_map[item_info[0]] = item_info[1]
	return craft_map

func craft_t(craft: String) -> Dictionary:
	var item_info := craft.split(":")
	return {item_info[0]: item_info[1]}

func fuel_t(fuel: String) -> Dictionary:
	var item_info := fuel.split(":")
	return {item_info[0]: item_info[1]}

