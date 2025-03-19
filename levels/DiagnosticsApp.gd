extends Node2D

@onready var ProgressBarNode := $SubViewportContainer/SubViewport/ProgressBar
@onready var subview := $SubViewportContainer/SubViewport
@onready var temp_text := $SubViewportContainer/SubViewport/TempSprite/TempText
@onready var heart_text := $SubViewportContainer/SubViewport/HeartSprite/HeartText

func _process(delta: float) -> void:
	#print(delta)
	#if ProgressBarNode.value < ProgressBarNode.max_value:
		#print( "Adding ")
		#ProgressBarNode.value = ProgressBarNode.value + (ProgressBarNode.step * 5) 
	#else:
		#ProgressBarNode.value = 0
	pass
