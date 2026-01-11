extends Event
class_name CollectableEvent

@export var collectables : Array[ItemDrop]
var collection_tracker : Dictionary[int, bool]
#I need to keep track of if things were collected, how?
#Wait for their interact calls and then change the value up here
#Once all values are the same

func _ready():
	for collectable in collectables:
		collectable.interacted.connect(_on_interact.bind(collectable))
		collection_tracker.set(collectable.get_instance_id(), false)
		
func _process(delta):
	#Once all collectables have been collected, finish event
	#collection_tracker.keys()
	pass

func _on_interact(collectable:ItemDrop):
	var id = collectable.get_instance_id()
	print("Interacted with:", [collectable.name,collection_tracker[id]])
	collection_tracker[id] = true
	if collection_tracker.values().has(false):
		print("Event not done.")
		pass
	else:
		print("No false in tracker left")
		event_fulfilled.emit()
