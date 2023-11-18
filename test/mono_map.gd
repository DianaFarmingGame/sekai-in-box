class_name MonoMap extends Node


@export var size := Vector2(0, 0)
@export var offset := Vector2(0, 0)
@export var data := PackedInt32Array([])
@export var overrides := {}

func draw(sekai: Sekai, pen: SekaiPen):
	for x in size.x:
		for y in size.y:
			var ref := data[y * size.x + x]
			sekai.call_ref_method(ref, &"draw_map", [pen, Vector2(x, y) + offset])
