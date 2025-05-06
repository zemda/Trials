extends EnemyIdle

@export_range(0.0, 1000.0) var ceiling_search_interval: float = 2.0
@export_range(1.0, 1000.0) var max_idle_time: float = 30.0

var _ceiling_search_timer: float = 0.0
var _idle_ceiling_timer: float = 0.0


func _enter() -> void:
	super._enter()
	_ceiling_search_timer = 0.0
	_idle_ceiling_timer = 0.0


func update(delta: float) -> void:
	super.update(delta)
	
	_ceiling_search_timer += delta
	_idle_ceiling_timer += delta
	
	if _ceiling_search_timer >= ceiling_search_interval:
		_ceiling_search_timer = 0.0
		if host.find_ceiling():
			emit_signal("transition_to", states.ATTACHING_CEILING)


func _transition() -> int:
	if _idle_ceiling_timer >= max_idle_time:
		return states.WANDER
	
	return super._transition()
