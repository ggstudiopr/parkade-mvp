extends Node
class_name Event

#What is an Event?
#Types of Events
#Collectables - Physically find 1> items
#Landmarks - Reach a specific location or notable landmark
#Photography - Record 1> items

#Augmenter
#Timed - Recurring or time sensitive event
#Enemy - Spawn enemy

#State of Events
signal event_fulfilled
signal event_failed
signal event_started

enum EVENT_STATE {
	PAUSED,
	IDLE,
	RUNNING,
	FAILED,
	FULFILLED
}

var current_state = EVENT_STATE.IDLE

#Things you need to interact with the event.
#They'll be fulfilled/spawned based on the int number. Same int numbers means spawning at the same time
@export var interactables : Array[ItemDrop]

func _ready():
	for interact in interactables:
		interact.connect("interacted",_on_interact)
	pass
func end_event(status : bool):
	if status == true:
		event_fulfilled.emit()
	else:
		event_failed.emit()

func run_event():
	event_started.emit()
	pass
	
func _on_interact(interactable: ItemDrop):
	var player
	interactable.interact(player)
