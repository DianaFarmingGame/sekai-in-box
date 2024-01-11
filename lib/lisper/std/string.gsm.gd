func gsm(): return ['

defunc (string/split :const :gd :pure ',
	func (pstr: String, split: String) -> Array:
		return Array(pstr.split(split))
,')

defunc (string/trim :const :gd :pure ',
	func (pstr: String) -> String:
		return pstr.strip_edges()
,')

defunc (string/join :const :gd :pure ',
	func (delimiter: String, ary: Array) -> String:
		return delimiter.join(ary)
,')

']
