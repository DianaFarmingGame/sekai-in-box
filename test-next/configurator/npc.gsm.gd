func gsm():
	return ['

csv/map-let(+(*config_base* "npc.csv")
	[ID ref 名称 位置X 位置Y 位置Z 图片/站立 图片/移动 图片/头像 行为]
	do (hako add_mono num(ref) {
		position vec3(num(位置X) num(位置Y) num(位置Z))
	})
)
']
