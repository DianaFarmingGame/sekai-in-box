func gsm(): return ['

defunc (define :const :gd :macro ',
	func (_ctx, body: Array) -> Array:
		return Lisper.apply(&"define/sign", [
			[Lisper.apply(&"define/make", [body])],
		])
,')

defunc (Define :const :gd :macro ',
	func (_ctx, body: Array) -> Array:
		return Lisper.apply(&"defvar", [
			[body[0]],
			[Lisper.apply(&"define/make", [
				body.slice(1),
			])],
		])
,')

defunc (import :const :gd :macro ',
	func (_ctx, body: Array) -> Array:
		return Lisper.apply(&"defvar", [[
			body[0],
			Lisper.apply(&"load", [
				body.slice(1),
			]),
		]])
,')

defunc (delay :const :gd ',
	func (ptimeout: float) -> void:
		await sekai.get_tree().create_timer(ptimeout).timeout
,')

']
