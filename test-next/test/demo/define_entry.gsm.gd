func gsm():
	return ['

var(init ', init,')
	
sekai/exec ("../../utils/utils.gss.txt")
sekai/exec ("../../.define.gss.txt")

var(*config_base* +(*mod-dir* "/csvs/"))

sekai/exec ("../../configurator/action.gsm.gd")
sekai/exec ("../../configurator/npc_define.gsm.gd")
;sekai/exec ("../../configurator/task.gsm.gd")
sekai/exec ("../../configurator/craft.gsm.gd")
sekai/exec ("../../configurator/item.gsm.gd")

init()

']

var init_data = {
	&"money": 10,
}

func init():
	var db = sekai.db
	for key in init_data:
		db.applymRSUY(sekai.context, &"db/set", [key, init_data[key], &"vals"])
