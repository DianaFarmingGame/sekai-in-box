class_name GItem extends GElement

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GItem"
	merge_traits(sets, [TGroup, TStackable, TIcon])
	merge_props(sets, {
		&"pickable": true, # 能否取得
		
		&"stackable": true, # 能否堆叠
		&"stack_count": 1, # 堆叠数量
		&"stack_capacity": 99, # 堆叠上限
	
		&"chargeable": true, # 能否修复
		&"charge_point": 1, # 可用度
		&"charge_capacity": 1, # 最高可用度
		
		&"tradeable": true, # 能否交易
		&"trade_price": 0, # 价格
		&"trade_stability": 1, # 保值度
	})
	return sets
