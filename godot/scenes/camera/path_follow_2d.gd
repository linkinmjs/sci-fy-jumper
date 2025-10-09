extends PathFollow2D

# Velocity (cantidad de pixeles)
@export var velocity: int

func _process(delta: float) -> void:
	progress += (velocity * delta)
