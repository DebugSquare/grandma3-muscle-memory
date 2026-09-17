class_name MAInteractionBase 
# Base for anything that recievies a osc message from MA
extends Node
func _init():
	OSCManager.message_received.connect(on_osc_message)

func on_osc_message(_address, _value, _time):
	pass
