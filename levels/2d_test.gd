extends Node2D

@onready var ProgressBarNode := $SubViewportContainer/SubViewport/ProgressBar

func _process(delta: float) -> void:
	print(delta)
	if ProgressBarNode.value < ProgressBarNode.max_value:
		print( "Adding ")
		ProgressBarNode.value = ProgressBarNode.value + (ProgressBarNode.step * 5) 
	else:
		ProgressBarNode.value = 0
