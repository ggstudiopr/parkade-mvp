extends Event

var jugs_collected = [false,false,false]

func _process(delta: float) -> void:
	if not jugs_collected.has(false):
		end_event(true)

#func _on_interact(interactable: Interactable):
#	match interactable.data['value']:
	#	1:
		#	jugs_collected[0] = true 
	#	2:
		#	jugs_collected[1] = true
		#3:
		#	jugs_collected[2] = true
