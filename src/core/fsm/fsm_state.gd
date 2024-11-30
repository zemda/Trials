class_name FSMState
extends Node

signal transition_to
signal transition_to_default
signal transition_to_last
signal state_exiting_tree(state: FSMState)

var state_name: StringName
var state_index: int
var state_active: bool = false
var is_exiting: bool = false
var is_entering: bool = false
var states: Dictionary
var host: Node


func enter():
	is_entering = true
	assert(states.size() > 2, 
		"State Error in " + name + 
		".gd: states has no states")
	await _enter()
	is_entering = false
	state_active = true


func _enter():
	pass


func exit():
	is_exiting = true
	await _exit()
	is_exiting = false
	state_active = false


func _exit():
	pass


func update(_delta: float) -> void:
	pass


func handle_transition() -> void:
	var trans = _transition()
	match trans:
		states.NONE:
			pass
		states.LAST:
			emit_signal("transition_to_last")
		_:
			emit_signal("transition_to", trans)


func _transition() -> int:
	return states.NONE


func is_busy() -> bool:
	return is_exiting or is_entering


func _exit_tree():
	emit_signal("state_exiting_tree", self)
