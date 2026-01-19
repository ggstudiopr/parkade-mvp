extends RigidBody3D
@export var locked : bool = true
##This node simply calls an animation to open whenever unlock is called upon it. Item Child can be configured to Lock and Key ID for the sake of interaction logic.
func unlock():
	$AnimationPlayer.play("open")
	locked = false

func doThing(node): #do nothing w node, only there to support DoThing logic across Objects
	if $Item.ID == Interactable.IDs.RemoteButton:
		unlock()
