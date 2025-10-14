extends PathFollow2D

# Velocity (cantidad de pixeles)
@export var velocity: int = 15

func _process(delta: float) -> void:
	if progress_ratio == 1.0:
		GameManager.can_add_scores = false
		return
	
	progress += (velocity * delta)
