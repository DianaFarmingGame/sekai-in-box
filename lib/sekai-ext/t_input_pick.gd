class_name TInputPick extends MonoTrait

var id := &"input_pick"

var requires := [&"container"]

var props := {
	&"on_picker_click": func(sekai: Sekai, this: Mono, cursor: Vector2) -> Variant:
		var monos := sekai.monos
		var pick := 100
		var pick_idx : int
		for mono_idx in range(len(monos)):
			var mono = monos[mono_idx]
			var value = mono.callm("click_check", cursor)
			if value != null and value < pick:
				pick = mono
				pick_idx = mono_idx
				
		if pick != 100:
			return monos[pick_idx]
		else:
			return null
		
}
