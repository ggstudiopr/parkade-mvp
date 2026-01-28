extends Node
class_name EventManager

signal all_events_finished

@export var events : Array[Event]
@export_subgroup("Info")
@export var events_running := 0
@export var events_paused := 0
@export var fulfilled_events := 0
@export var failed_events := 0
@export_subgroup("")

func _ready():
	for event in events:
		event.connect("event_fulfilled", _on_event_fulfilled)
		event.connect("event_failed", _on_event_failed)
		event.connect("event_started",_on_event_started)
		event.connect("event_paused", _on_event_paused)
	pass
func _process(delta):
	#I shouldnt need to check this every tick but im too tired to do it right
	if fulfilled_events + failed_events == events.size():
		all_events_finished.emit()

func pause_events():
	for event in events:
		event.pause_event()

func _on_event_started():
	events_running += 1
	
func _on_event_paused():
	#TODO: Very rudimentary WILL BE WRONG WHEN UNPAUSED
	events_running -= 1 if events_running > 0 else events_running 
	events_paused +=1
	
func _on_event_failed():
	failed_events += 1

func _on_event_fulfilled():
	fulfilled_events += 1
	#TODO: Once fulfilled events is equal to size of events, call all events_finished function
