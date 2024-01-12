var gtx: LisperContext

func get_base(name: String):
	return gtx.get_var(name)

func gsm():
	return ["""
	defunc (get_base :gd """, get_base,""")

	csv/map-let(+(*config_base* "item.csv")
		[ref ID 名称 描述 组 能否取得 能否堆叠 堆叠上限 能否修复 最高可用度 主要行为消耗 次要行为的消耗 能否交易 价格 保值度 图片/图标]

		define(get_base(组)
			ref num(ref)
			id 	keyword(ID)
			props {
				name 				名称
				description 		描述
				groups 				prop/pushs([组])
				icon 				[&icon rect2(0 0 32 32)]
	
				&stackable 			能否堆叠
				&stack_capacity		堆叠上限
	
				&chargeable			能否修复
				&charge_capacity 	num (最高可用度)
	
				&primary_charge 	主要行为消耗
				&secondary_charge	次要行为的消耗
	
				&tradeable			能否交易
				&trade_price		num (价格)
				&trade_stability	num (保值度)
	
				asserts {
					icon 图片/图标
				}
	
				action {
					default & ; 攻击
					smash & ; 破坏方块
				}
			}
		)
	)

"""]
