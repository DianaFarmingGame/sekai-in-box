extends Control

var this: Mono
var context: LisperContext

var mp:
	set(v):
		$TextureProgressBar.value = v

var money:
	set(v):
		$TextureRect/Label.text = v

func _ready():
	#mp = this.getp(&"ap")
	#money = this.getp(&"money")
	pass
