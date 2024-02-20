func gsm():
	return ['
	csv/map-let(+(*config_base* "item.csv")
		[ref ID 名称 描述 组 能否堆叠 堆叠上限 能否修复 最高可用度 主要行为消耗 次要行为的消耗 能否交易 价格 保值度 图片/图标]

		define(load("../define/物品/item.gd")
			ref num(ref)
			id 	keyword(ID)
			props {
				name 				名称
				description 		描述
				groups 				prop/pushs([组])
				icon 				[&icon rect2(0 0 32 32)]
	
				&can_stack 			能否堆叠
				&stack_capacity		堆叠上限
	
				&can_charge			能否修复
				&charge_capacity 	num (最高可用度)
	
				&primary_charge 	主要行为消耗
				&secondary_charge	次要行为的消耗
	
				&can_trade			能否交易
				&trade_price		num (价格)
				&trade_stability	num (保值度)
	
				asserts {
					icon load(+("asserts/" 图片/图标))
				}

				icon [&icon rect2(0 0 32 32)]
			}
		)
	)

']
