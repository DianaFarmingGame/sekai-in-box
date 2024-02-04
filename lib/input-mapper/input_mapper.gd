class_name InputMapper

signal updated(triggered: Dictionary, pressings: Dictionary, releasings: Dictionary)

var triggered_actions := {}

func update(event: InputEvent, dir = null) -> void:
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
	updated.emit(triggered_actions, pressings, releasings)

class InputSet:
	var direction: Vector3
	var triggered: Dictionary
	var pressings: Dictionary
	var releasings: Dictionary
	func _init(pdirection: Vector3, ptriggered: Dictionary, ppressings: Dictionary, preleasings: Dictionary) -> void:
		direction = pdirection
		triggered = ptriggered
		pressings = ppressings
		releasings = preleasings
