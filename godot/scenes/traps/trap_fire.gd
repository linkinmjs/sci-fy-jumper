extends AnimatedSprite2D

@export var wait_time_activation: float = 2
@onready var activation_timer: Timer = $ActivationTimer
@onready var trap_fire: AnimatedSprite2D = $"."

func _ready() -> void:
	activation_timer.wait_time = wait_time_activation
	activation_timer.timeout.connect(_on_activation_timer_timeout)
	
func _on_activation_timer_timeout():
	play("activate")
