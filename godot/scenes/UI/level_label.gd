extends Label

func _ready() -> void:
	text = "Level %s" % str(GameManager.actual_level)
	GameManager.changel_level.connect(_on_change_level)
	
func _on_change_level() -> void:
	text = "Level %s" % str(GameManager.actual_level)
