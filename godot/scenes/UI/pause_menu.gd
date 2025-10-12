extends Node2D

@onready var pause_menu: Panel = $CanvasLayer/Panel

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("esc"):
		pause_or_unpause()

func pause_or_unpause() -> void:
	if get_tree().paused == true:
		pause_menu.hide()
		get_tree().paused = false
	elif get_tree().paused == false:
		pause_menu.show()
		get_tree().paused = true
