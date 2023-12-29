class_name GItem extends GElement

func do_merge(sets: Array[Dictionary]) -> Array[Dictionary]:
	super.do_merge(sets)
	name = "GItem"
	merge_traits(sets, [TGroup])
	merge_props(sets, {
		&"pickable": true, # 能否取得
		
		&"stackable": true, # 能否堆叠
		&"stack_capacity": 99, # 堆叠上限
		&"stack_count": 1, # 堆叠数量
	
		&"lp": 0, # 可用度
		&"chargeable": true, # 能否修复
		
		&"tradeable": true, # 能否交易
		&"price": 0, # 价格
	})
	return sets
