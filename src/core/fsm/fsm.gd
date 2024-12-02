class_name FSM
extends Node

@export_node_path("FSMState") var default_state_path
@export_range(1, 100) var history_buffer_size: int = 10

var host: Node : set = set_host
var current_state: FSMState : set = change_state
var state_history: Array[FSMState]
var state_list: Array[FSMState]
var states: Dictionary = {"NONE" = -1, "LAST" = -2}

@onready var default_state: FSMState = get_node(default_state_path)


func _ready() -> void:
	_set_up_fsm()


func _set_up_fsm() -> void:
	for i in get_children():
		if i is FSMState:
			add_state(i)


func set_host(n: Node) -> void:
	host = n
	if host:
		for i in state_list:
			if i is FSMState:
				i.host = host
		change_state_to_default()


func add_state(state: FSMState) -> void:
	state.connect("transition_to", change_state_to)
	state.connect("transition_to_default", change_state_to_default)
	state.connect("transition_to_last", change_state_to_last)
	
	state.connect("state_exiting_tree", remove_state)
	state.states = states
	
	var state_name: StringName = _get_trimmed_name(state.name)
	var state_index: int = 0
	
	while states.values().has(state_index):
		state_index += 1
	
	state.state_name = state_name
	state.state_index = state_index
	
	states[state_name] = state_index
	state_list.append(state)
	
	if host:
		state.host = host


func remove_state(state: FSMState) -> void:
	state.disconnect("transition_to", change_state_to)
	state.disconnect("transition_to_default", change_state_to_default)
	state.disconnect("transition_to_last", change_state_to_last)
	
	states.erase(state.state_name)
	state_list.erase(state)
	
	state.host = null


func change_state_to(index: int) -> void:
	change_state(state_list[index])


func change_state_to_default() -> void:
	change_state(default_state)


func change_state_to_last() -> void:
	if not state_history.is_empty():
		change_state(state_history.back())
	else:
		change_state_to_default()


func change_state(new_state: FSMState) -> void:
	var old_state: FSMState = current_state
	if old_state:
		_track_state(old_state)
		await old_state.exit()
	current_state = new_state
	
	await current_state.enter()


func _physics_process(delta: float) -> void:
	if host:
		if current_state:
			if current_state.state_active:
				current_state.update(delta)
			
			if not current_state.is_busy():
				current_state.handle_transition()


func _track_state(state: FSMState) -> void:
	if state_history.size() == history_buffer_size:
		state_history.remove_at(0)
	state_history.append(state)


func _get_trimmed_name(state_name: String) -> StringName:
	return state_name.substr(state_name.find("_") + 1).to_upper() as StringName
