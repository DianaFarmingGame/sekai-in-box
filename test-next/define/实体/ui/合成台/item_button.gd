extends TextureButton

signal press(index)
signal get_item(ref)

func _ready():
	self.pressed.connect(self._on_pressed)

func _on_pressed():
	emit_signal("press", get_index())
	
var texture: Texture2D:
	set(v):
		$TextureRect.texture = v
		
var item_name: String:
	set(v):
		$Name.text = v
		
var remain_time: int:
	set(v):
		$Ramain.text = get_string_time(v)
		remain_time = v
		
var ref: int
		
func finish() -> void:
	$Ramain.hide()
	$Finish.show()

func get_string_time(time: int) -> String:
	var second = time % 60
	var minute = (time / 60) % 60
	var hour = time / 3600
	var str_second = str(second) if second >= 10 else "0" + str(second)
	var str_minute = str(minute) if minute >= 10 else "0" + str(minute)
	var str_hour = str(hour) if hour >= 10 else "0" + str(hour)
	return str_hour + ":" + str_minute + ":" + str_second

func _on_finish_pressed():
	emit_signal("get_item", ref)
