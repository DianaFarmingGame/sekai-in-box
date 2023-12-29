extends Control

func set_traveler_hp_max(value: int):
	$traveler/hp_progress.max_value = value
	$traveler/max_hp.text = "/ " + str(value)
	
func set_traveler_hp(value: int):
	$traveler/hp_progress.value = value
	$traveler/hp.text = str(value)
	
func set_traveler_mp_max(value: int):
	$traveler/mp_progress.max_value = value
	$traveler/max_mp.text = "/ " + str(value)
	
func set_traveler_mp(value: int):
	$traveler/mp_progress.value = value
	$traveler/mp.text = str(value)
	
func set_diana_hp_max(value: int):
	$diana/hp_progress.max_value = value
	$diana/max_hp.text = "/ " + str(value)
	
func set_diana_hp(value: int):
	$diana/hp_progress.value = value
	$diana/hp.text = str(value)
	
func set_diana_mp_max(value: int):
	$diana/mp_progress.max_value = value
	$diana/max_mp.text = "/ " + str(value)
	
func set_diana_mp(value: int):
	$diana/mp_progress.value = value
	$diana/mp.text = str(value)

func set_money(value: int):
	$money/num.text = str(value)
	
func show_traveler():
	$traveler.show()
	$diana.hide()
	
func show_diana():
	$diana.show()
	$traveler.hide()

func get_time():
	return $WorldTime.game_time
