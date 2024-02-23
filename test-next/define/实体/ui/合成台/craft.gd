extends TextureRect

const ItemButton = preload("res://test-next/define/实体/ui/合成台/item_button.tscn")
const Fail = preload("res://test-next/define/实体/ui/合成台/fade.tscn")
const Dialog = preload("res://test-next/define/实体/ui/对话框/head_dialog.tscn")

var this: Mono
var target: Mono
var context: LisperContext
var control: SekaiControl

var craft_list: Dictionary
var on_craft_list: Dictionary
var finished_list: Array
var inventory: Dictionary
var cur_ref: int
var ref_2_index: Dictionary

func _ready():
	get_craft_list()
	
func _process(delta):
	for ref in on_craft_list:
		on_craft_list[ref] -= delta
		if on_craft_list[ref] <= 0:
			var node = %CraftList.get_child(ref_2_index[ref])
			node.finish()
			on_craft_list.erase(ref)
			finished_list.append(ref)
	update_remain_time(on_craft_list)
	
func get_craft_list():
	# 获取所有合成公式
	var list = sekai.db.callmRSUY(context, &"db/getg", &"craft")
	for record in list.values():
		var ref
		for id in record["craft"]:
			var item = sekai.get_define(id)
			if item == null:
				continue
			var num = record["craft"][id]
			ref = item.ref
			craft_list[ref] = {}
			craft_list[ref]["item_name"] = item.get_prop(&"name")
			craft_list[ref]["texture"] = item.get_prop(&"asserts")[&"icon"]
			craft_list[ref]["num"] = num
		if ref == null:
			continue
		craft_list[ref]["remain_time"] = record["time"]
		for id in record["need"]:
			var item = sekai.get_define(id)
			if item == null:
				continue
			var need_num = record["need"][id]
			# mock
			var need_ref = 3000
			craft_list[ref]["needs"] = {}
			craft_list[ref]["needs"][need_ref] = {}
			craft_list[ref]["needs"][need_ref]["num"] = need_num
			craft_list[ref]["needs"][need_ref]["texture"] = item.get_prop(&"asserts")[&"icon"]
		craft_list[ref]["describe"] = record["desc"]
		

func update_view():
	clear()
	update_inventory()
	$check.hide()
	# 优先展示合成完的物品
	for ref in finished_list:
		var node = create_craft_node(ref)
		node.finish()
		%CraftList.add_child(node)
		ref_2_index[ref] = node.get_index()
	# 其次展示合成中的物品
	for ref in on_craft_list:
		var node = create_craft_node(ref)
		node.remain_time = int(on_craft_list[ref])
		%CraftList.add_child(node)
		ref_2_index[ref] = node.get_index()
	# 最后展示剩余物品
	for ref in craft_list:
		if on_craft_list.has(ref) or finished_list.has(ref):
			continue
		var node = create_craft_node(ref)
		%CraftList.add_child(node)
		ref_2_index[ref] = node.get_index()

func create_craft_node(ref: int) -> Node:
	var node = ItemButton.instantiate()
	node.ref = ref
	node.item_name = craft_list[ref]["item_name"]
	node.remain_time = craft_list[ref]["remain_time"]
	if craft_list[ref]["texture"] != null:
		node.texture = craft_list[ref]["texture"]
	else :
		node.texture = load("res://test-next/define/物品/卷轴.png")
	node.connect("press", _on_button_pressed)
	node.connect("get_item", _on_get_item_pressed)
	return node

func clear():
	for child in %CraftList.get_children():
		child.free()
	clear_detail()
	
func clear_detail():
	$describe.text = ""
	$Target.clear()
	for slot in $Needs.get_children():
		slot.clear()

func update_inventory() -> void:
	var contains := this.getp(&"contains") as Array
	var new_inventory = {}
	for mono in contains:
		var ref = mono.define.ref
		var num = mono.getp(&"stack_count")
		new_inventory[ref] = new_inventory[ref] + num if new_inventory.has(ref) else num
	inventory = new_inventory
	
func update_needs() -> void:
	var cur = 0
	for need_ref in craft_list[cur_ref]["needs"]:
		var need_num = craft_list[cur_ref]["needs"][need_ref]["num"]
		var cur_num = inventory.get(need_ref, 0)
		var slot = $Needs.get_child(cur)
		cur += 1
		slot.label = "(" + str(cur_num) + "/" + str(need_num) + ")"
		if craft_list[cur_ref]["needs"][need_ref]["texture"] != null:
			slot.item_texture = craft_list[cur_ref]["needs"][need_ref]["texture"]
		else :
			slot.item_texture = load("res://test-next/define/物品/卷轴.png")

func update_remain_time(on_craft_list) -> void:
	for ref in on_craft_list:
		var node = %CraftList.get_child(ref_2_index[ref])
		node.remain_time = int(on_craft_list[ref])
	

func _on_button_pressed(index):
	clear_detail()
	var cur_node = %CraftList.get_child(index)
	cur_ref = cur_node.ref
	if on_craft_list.has(cur_ref) or finished_list.has(cur_ref):
		$check.hide()
	else :
		$check.show()
	$describe.text = craft_list[cur_ref]["describe"]
	$Target.label = str(craft_list[cur_ref]["num"])
	if craft_list[cur_ref]["texture"] != null:
		$Target.item_texture = craft_list[cur_ref]["texture"]
	else :
		$Target.item_texture = load("res://test-next/define/物品/卷轴.png")
	update_needs()

func _on_check_pressed():
	update_inventory()
	var cur_needs = craft_list[cur_ref]["needs"]
	for need_ref in cur_needs:
		if inventory[need_ref] < cur_needs[need_ref]["num"]:
			var node = Fail.instantiate()
			add_child(node)
			return
	for need_ref in cur_needs:
		await this.applym(context, &"container/pick_by_ref_id", [need_ref, cur_needs[need_ref]["num"]])
	on_craft_list[cur_ref] = float(craft_list[cur_ref]["remain_time"])
	update_inventory()
	update_view()

func _on_close_pressed():
	await this.callmRS(context, &"craft/toggle", control)

func _on_get_item_pressed(ref):
	await this.applym(context, &"container/add", [ref, {}])
	finished_list.erase(ref)
	await this.callmRS(context, &"craft/toggle", control)
