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
defunc (int :gd """, float2int,""")

var(craft_idx 0)

csv/map-let(+(*config_base* "craft.csv")
	[需求物品 合成物品 描述 合成时间]
	block(
		++(craft_idx)
		do(db db/set int(craft_idx) {
				need need_t(需求物品)
				craft craft_t(合成物品)
	
				time num(合成时间)
	
				desc 描述
			} "craft"
		)
	)
)

var(enhance_idx 0)

csv/map-let(+(*config_base* "enhance.csv")
	[需求物品 合成物品 描述 合成时间]
	block(
		++(enhance_idx)
		do (db db/set int(enhance_idx) {
				need need_t(需求物品)
				craft craft_t(合成物品)
	
				time num(合成时间)
	
				desc 描述
			} "enhance"
		)
	)
)

var(cook_idx 0)

csv/map-let(+(*config_base* "cook.csv")
	[需求物品 合成物品 描述 合成时间]
	block(
		++(cook_idx)
		do (db db/set int(cook_idx) {
				need need_t(需求物品)
				craft craft_t(合成物品)
	
				time num(合成时间)
	
				desc 描述
			} "cook"
		)
	)
)

"""]

func craft2ID(craft: String) -> StringName:
	return StringName(craft.split(":")[0])

func need_t(need: String) -> Dictionary:
	var item_list := need.split(" ")
	var craft_map := {}
	for item in item_list:
		if item == "":
			continue
		var item_info := item.split(":")
		craft_map[StringName(item_info[0])] = int(item_info[1])
	return craft_map

func craft_t(craft: String) -> Dictionary:
	var item_info := craft.split(":")
	return {StringName(item_info[0]): int(item_info[1])}

func fuel_t(fuel: String) -> Dictionary:
	var item_info := fuel.split(":")
	return {StringName(item_info[0]): int(item_info[1])}

func float2int(f: float) -> int:
	return int(f)
