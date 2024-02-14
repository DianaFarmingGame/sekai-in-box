class_name TKVContainer extends MonoTrait

var id := &"kv_container"

var props := {
	&"kvs": {},

	&"kv/set": func(ctx: LisperContext, this: Mono, key: String, value):
		var kvs = this.getp(&"kvs") as Dictionary

		if kvs.has(key):
			push_warning("[kv/set] define exist key: " + key)
			return

		kvs[key] = value
		,

	&"kv/get": func(ctx: LisperContext, this: Mono, key: String) -> Variant:
		var kvs = this.getp(&"kvs") as Dictionary

		if not kvs.has(key):
			push_error("[kv/get] key not found: " + key)
			return null

		return kvs[key]
		,

	&"kv/del": func(ctx: LisperContext, this: Mono, key: String):
		var kvs = this.getp(&"kvs") as Dictionary

		if not kvs.has(key):
			push_warning("[kv/del] key not found: " + key)
			return

		kvs.erase(key)
		,

	
}

