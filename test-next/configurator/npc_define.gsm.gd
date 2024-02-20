func gsm():
	return ['

csv/map-let(+(*config_base* "npc.csv")
	[ID ref 名称 位置X 位置Y 位置Z 图片/站立 图片/移动 图片/头像 行为]
	define(load ("../define/实体/npc.gd")
		ref num(ref)
		id 	ID
		props {
			solid_box rect2(-0.3 -0.1 0.6 0.2)
			name 名称
			asserts {
				idle 	load(#("asserts/" + 图片/站立 + ".png"))
				walk 	load(#("asserts/" + 图片/移动 + ".png"))
				avatar 	load(#("asserts/" + 图片/头像 + ".png"))
			}

			draw_data {
				idle [&fixed &idle 0.6 anim_char(4)]
				walk [&fixed &walk 0.4 anim_char(8)]
			}
			
			action_data {
				primary keyword(行为)
			}
		}
	)

)
']
