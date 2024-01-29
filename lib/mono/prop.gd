class_name Prop

static func setp(data: Variant) -> Action:
	return Action.new(ActType.SETP, data)

static func pushs(data: Array) -> Action:
	return Action.new(ActType.PUSHS, data)

static func puts(data: Variant) -> Action:
	return Action.new(ActType.PUTS, data)

static func mergep(data: Variant) -> Action:
	return Action.new(ActType.MERGEP, data)

static func StackEntry(head: StringName, body: Variant) -> Array:
	return [[head, body]]

static func Stack(data: Variant) -> Array:
	assert(data is Dictionary or data is Array)
	if data is Dictionary:
		data = do_puts([], data)
	return data

enum ActType {
	SETP,
	PUSHS,
	PUTS,
	MERGEP,
}

class Action:
	var type: ActType
	var data: Variant
	func _init(ptype: ActType, pdata: Variant) -> void:
		type = ptype
		data = pdata

static func do_setp(_tar: Variant, src: Variant) -> Variant:
	return src

static func do_pushs(tar: Array, src: Array) -> Array:
	tar.append_array(src)
	return tar

static func do_puts(tar: Array, src: Variant) -> Array:
	assert(src is Array or src is Dictionary)
	if src is Dictionary:
		src = src.keys().map(func (k): return [k, src[k]])
	for entry in src:
		var w := float(entry[0])
		var bidx := 0
		while bidx < tar.size():
			if w < float(tar[bidx][0]): break
			bidx += 1
		tar.insert(bidx, entry)
	return tar

static func do_mergep(tar: Dictionary, src: Variant) -> Dictionary:
	assert(src is Array or src is Dictionary)
	if src is Array:
		var nsrc := {}
		for entry in src:
			assert(entry[0] is StringName)
			nsrc[entry[0]] = entry[1]
		src = nsrc
	for key in src.keys():
		var srcp = src[key]
		var tarp = tar.get(key)
		if srcp is Dictionary:
			if tarp is Dictionary:
				tar[key] = do_mergep(tarp, srcp)
			elif tarp is Array:
				tar[key] = do_puts(tarp, srcp)
			else:
				tar[key] = do_setp(tarp, srcp)
		elif srcp is Array:
			if tarp is Dictionary:
				tar[key] = do_mergep(tarp, srcp)
			elif tarp is Array:
				tar[key] = do_setp(tarp, srcp)
			else:
				tar[key] = do_setp(tarp, srcp)
		elif srcp is Action:
			match srcp.type:
				ActType.SETP:
					tar[key] = do_setp(tarp, srcp.data)
				ActType.PUSHS:
					tar[key] = do_pushs(tarp, srcp.data)
				ActType.PUTS:
					tar[key] = do_puts(tarp, srcp.data)
				ActType.MERGEP:
					tar[key] = do_mergep(tarp, srcp.data)
		else:
			tar[key] = do_setp(tarp, srcp)
	return tar
