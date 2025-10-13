extends Label

func _ready() -> void:
	text = "Score: %s" % str(GameManager.score)
