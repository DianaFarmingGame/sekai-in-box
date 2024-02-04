class_name InputMapper

signal updated(set: InputSet)

var triggered_actions := {}

var cur_direction := Vector2(0, 0)

func update(event: InputEvent, dir = null) -> void:
	if dir != null: cur_direction = dir
	var pressings := {}
	var releasings := {}
	for action in InputMap.get_actions():
		if event.is_action(action):
			var obj = triggered_actions.get(action, [0])
			if event.is_action_pressed(action):
				obj[0] += 1
				pressings[action] = obj
			if event.is_action_released(action):
				obj[0] -= 1
				releasings[action] = obj
			if obj[0] > 0:
				triggered_actions[action] = obj
			else:
				triggered_actions.erase(action)
	updated.emit(InputSet.new(cur_direction, triggered_actions, pressings, releasings))
