extends Event
class_name CollectableEvent

var collection_tracker : Dictionary[int, bool]

func _ready():
	for collectable in interactables:
		collection_tracker.set(collectable.get_instance_id(), false)
	super._ready()

func _on_interact(collectable:ItemDrop):
	var id = collectable.get_instance_id()
	print("Interacted with:", [collectable.name,collection_tracker[id]])
	collection_tracker[id] = true
	if collection_tracker.values().has(false):
		pass
	else:
		end_event(EVENT_STATE.FULFILLED)

func pause_event():
	pass
