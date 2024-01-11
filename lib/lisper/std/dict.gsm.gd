func gsm(): return ['

defunc (dict/for :const :gd :apply :pure ',
	func (ctx: LisperContext, args: Array) -> void:
		var dict := args[0] as Dictionary
		var handle = args[1]
		if not ctx.check_valid_handle(handle): return
		for key in dict.keys():
			await ctx.call_fn(handle, [key, dict[key]])
,')

']
