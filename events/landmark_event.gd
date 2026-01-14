extends Event
class_name LandmarkEvent

@export var landmarks : Dictionary[Area3D, Animation]
@export var animation_player : AnimationPlayer

func _ready():
	for landmark in landmarks:
		landmark.body_entered.connect(_on_landmark_entered.bind(landmark))
		
func _on_landmark_entered(body: Node3D, landmark:Area3D):
	if body is Protagonist:
		if landmark in landmarks:
			animation_player.play(landmarks[landmark].resource_name)
			end_event(EVENT_STATE.FULFILLED)

func pause_event():
	for landmark in landmarks:
		landmark.monitoring = false

func unpause_event():
	for landmark in landmarks:
		landmark.monitoring = true	
