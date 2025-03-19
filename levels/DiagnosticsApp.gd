extends Node2D
@onready var PHONE := $".."
@onready var subview := $SubViewportContainer/SubViewport


#basic access node declarations
@onready var ICONS := $SubViewportContainer/SubViewport/Icons
@onready var temp_text := $SubViewportContainer/SubViewport/Icons/TempSprite/TempText
@onready var heart_text := $SubViewportContainer/SubViewport/Icons/HeartSprite/HeartText
@onready var ProgressBarNode := $SubViewportContainer/SubViewport/Icons/ProgressBar

func _process(delta: float) -> void:
	pass
