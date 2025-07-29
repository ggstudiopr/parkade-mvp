extends Node
class_name EventManager

#Handles the events

signal all_events_finished

@export var events : Array[Event]
var fulfilled_events : int
var failed_events: int

func _ready():
	for event in events:
		event.connect("event_fulfilled", _on_event_fulfilled)
		event.connect("event_failed", _on_event_failed)
		event.connect("event_started",_on_event_started)

func _process(delta):
	#I shouldnt need to check this every tick but im too tired to do it right
	if fulfilled_events + failed_events == events.size():
		all_events_finished.emit()

func _on_event_started():
	pass
	
func _on_event_failed():
	pass

func _on_event_fulfilled():
	fulfilled_events = fulfilled_events + 1
