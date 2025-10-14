extends PathFollow2D

# Velocity (cantidad de pixeles)
@export var initial_vel: int = 16
@export var multiplier_vel: int = 4
var velocity: int = 16

func _ready() -> void:
	print("Velocidad del nivel: %s" % velocity)
	if GameManager.actual_level == 1:
		return
	velocity = initial_vel + (multiplier_vel * GameManager.actual_level)
	print("Velocidad del nivel: %s" % velocity)


func _process(delta: float) -> void:
	if progress_ratio == 1.0:
		GameManager.can_add_scores = false
		return
	
	progress += (velocity * delta)
