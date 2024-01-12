func gsm():
	return ['

csv/map-let(+(*config_base* "npc.csv")
	[ID 名称 位置X 位置Y 位置Z 图片/站立 图片/移动 图片/头像 行为]
	mono( 
		MonoEntity &实体/NPC
			props {
				name 名称
				position vec3(num(位置X) num(位置Y) num(位置Z))
				asserts {
					idle 图片/站立
					walk 图片/移动
				}
				
				actions {
					interact dbs/get(["行为" 行为])
				}
			}

	)
)
']