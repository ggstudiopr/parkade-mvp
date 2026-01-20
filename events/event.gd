extends Node
class_name Event

#Augmenter
#Timed - Recurring or time sensitive event
#Enemy - Spawn enemy


#State of Events
signal event_fulfilled
signal event_failed
signal event_started
signal event_paused

enum EVENT_TYPE {
	COLLECTABLE, #Physically find 1> items in the world
	LANDMARK, #Reach a specific location in the world
	PHOTOGRAPH, #Record 1> items on your phone
}

enum EVENT_STATE {
	PAUSED,
	IDLE,
	RUNNING,
	FAILED,
	FULFILLED
}

@export var current_state = EVENT_STATE.IDLE

#Things you need to interact with the event.
#They'll be fulfilled/spawned based on the int number. Same int numbers means spawning at the same time
@export var interactables : Array[Interactable]

func _ready():
	for interactable in interactables:
		interactable.interacted.connect(_on_interact.bind(interactable))
	run_event()

func end_event(status : EVENT_STATE):
	match status: 
		EVENT_STATE.FULFILLED:
			current_state = status
			event_fulfilled.emit()
		EVENT_STATE.FAILED:
			current_state = EVENT_STATE.FAILED
			event_failed.emit()

func pause_event():
	#TODO: Implement general pause...maybe?
	current_state = EVENT_STATE.PAUSED
	event_paused.emit()

func run_event():
	current_state = EVENT_STATE.RUNNING
	event_started.emit()
	
func _on_interact(interactable: Interactable):
	#interactable.interact() #[GR] recursive call? #[Gabe] Tru, good catch. I'll delete on next catch up.
	pass
