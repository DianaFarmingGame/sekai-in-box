func gsm():
	return ['

csv/map-let(+(*config_base* "npc.csv")
	[ID ref 名称 位置X 位置Y 位置Z 图片/站立 图片/移动 图片/头像 行为]
	define(Character
		ref 	num(ref)
		id 		keyword(ID)
		props {
			name 名称
			solid_box rect2(-0.3 -0.1 0.6 0.2)
			asserts {
				idle 图片/站立
				walk 图片/移动
			}

			draw_data {
				idle [&fixed &idle 0.6 anim_char(4)]
				walk [&fixed &walk 0.4 anim_char(8)]
			}

			actions {
				interact dbs/get(["行为" 行为])
			}
		}
	)
)
']