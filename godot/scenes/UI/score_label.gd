extends Label

const SCORE_WIDTH := 7 # usado para completar con Ceros

func _ready() -> void:
	GameManager.adding_score.connect(_on_adding_score)

func _on_adding_score() -> void:
	var padded := str(GameManager.score).pad_zeros(SCORE_WIDTH)
	text = "Score: %s" % padded
