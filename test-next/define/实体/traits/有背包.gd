class_name 有背包 extends MonoTrait

var id := &"有背包"
var traits := [TContainer]
var requires := []

var props := {
	&"exchange_item": func(ctx: LisperContext, this: Mono, input_item: Dictionary, output_item: Dictionary) -> int:
		var flag := 0

		var inputs = []

		for item in input_item:
			var item_id = item
			var item_num = input_item[item]

			var item_mono = sekai.make_mono(item_id, {&"props": {&"stack_count": item_num}})

			inputs.append(item_mono)

		var container = this.getp(&"contains")
		var container_d = []

		for mono in container:
			container_d.append(mono.clone())

		while true:
			for i in output_item:
				if !await this.applym(ctx, &"container/get_by_ref_id", [i, output_item[i]]):
					flag = 1
					break
			if flag != 0: break

			for i in inputs:
				if !await this.callm(ctx, &"container/put", i):
					flag = 2
					break
			if flag != 0: break
			break

		if flag != 0:
			this.setp(&"contains", container_d)

		return flag
		,
	#--------------------------------------------------------------------------#

}
