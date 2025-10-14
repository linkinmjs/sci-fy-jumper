extends Label

const SCORE_WIDTH := 7 # usado para completar con Ceros

func _ready() -> void:
	GameManager.adding_score.connect(_update_score)
	GameManager.restart_game.connect(restart_score)
	_update_score()

func _update_score() -> void:
	var padded := str(GameManager.score).pad_zeros(SCORE_WIDTH)
	text = "Score: %s" % padded

func restart_score() -> void:
	text = "Score: 0000000"
