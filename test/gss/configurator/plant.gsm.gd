

func gsm():
	return ['

csv/map-let(+(*config_base* "plant.csv")
	[ID 所需时间 下一阶段ID]

	dbs/define(["种植" ID {
			duration	所需时间
			next		下一阶段ID
		}
	])
)	

']