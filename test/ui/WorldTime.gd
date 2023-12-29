extends Node2D

const START_TIME = "2022-03-07 00:00:00"

var game_time: int : set = time_update
var start_time: int

func _ready() -> void:
	start_time = Time.get_unix_time_from_datetime_string(START_TIME)
	game_time = start_time

func _process(delta: float) -> void:
	var process_time = Time.get_ticks_msec() / 1000
	game_time = start_time + (process_time * 60 * 10)

func time_update(value):
	game_time = value
	var date_time = Time.get_datetime_dict_from_unix_time(game_time)
	$month.text = str(date_time['month'])
	$day.text = str(date_time['day'])
	$hour.text = str(date_time['hour'])
	$minute.text = str(date_time['minute'])
	var hour = date_time['hour']
#	var node = get_tree().root.get_node("MainWorld/sun")
#	if hour == 18 or hour == 19:
#		node.status = Alternation.DayTime.SUNSET
#	elif hour == 5 or hour == 6:
#		node.status = Alternation.DayTime.SUNRISE
#	else:
#		node.status = Alternation.DayTime.NORMAL
