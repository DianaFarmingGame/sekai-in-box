

func gsm():
	return ['
	csv/map-let(+(*config_base* "task.csv")
	[ID 任务名]
	dbs/define(["任务" keyword(ID) {
			name	任务名
			isOpen	#f
			desc	""
		}
	])
)

']

