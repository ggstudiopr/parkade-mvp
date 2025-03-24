extends Node
class_name Event

#What is an Event?

#State of Events
signal event_fulfilled
signal event_failed
signal event_started

#Things you need to interact with to fulfill the event.
#They'll be fulfilled/spawned based on the int number. Same int numbers means spawning at the same time
@export var interactables : Dictionary[int, Interactable] = {}
