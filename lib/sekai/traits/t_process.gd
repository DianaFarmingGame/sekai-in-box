class_name TProcess extends MonoTrait

var id := &"process"

var props := {
	&"need_process": true,
	&"processing": true, # TODO
	&"on_process": Prop.Stack(),
}
