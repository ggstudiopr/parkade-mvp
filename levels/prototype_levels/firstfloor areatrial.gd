extends Area3D
@onready var player :=  $"../Protagonist"


func _on_body_entered(body: Node3D) -> void:

	if body == player:
		if !$AnimationPlayer.is_playing():
			$AnimationPlayer.play("state1")

	pass # Replace with function body.
