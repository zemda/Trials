extends MasterChain

func _ready() -> void:
	create_chain()
	_add_segments_to_group()


func _add_segments_to_group() -> void:
	for s in segments:
		s.add_to_group("Chain")
