extends Event
class_name InteractableEvent 

@export var event_interactables : Dictionary[Interactable, Animation]
@export var animation_player : AnimationPlayer

func _ready():
	for interactable in event_interactables:
		interactable.interacted.connect(_on_interacted.bind(interactable))
		

func _on_interacted(interactable: Interactable):
	print("Interacted with:",interactable)
	animation_player.play(event_interactables[interactable].resource_name)
