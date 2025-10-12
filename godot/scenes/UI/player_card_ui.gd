extends Node2D

@onready var energy: AnimatedSprite2D = $Energy
@onready var health: AnimatedSprite2D = $Health

func _ready() -> void:
	GameManager.laser_is_shooted.connect(decrese_energy)
	GameManager.player_is_hitted.connect(decrese_life)

func decrese_energy() -> void:
	var actual_frame = energy.frame
	energy.set_frame(actual_frame+1)
	if GameManager.actual_energy <= 0:
		energy.hide()
	
func decrese_life() -> void:
	print(GameManager.actual_life)
	var actual_frame = health.frame
	health.set_frame(actual_frame+1)
	if GameManager.actual_life <= 0:
		health.hide()
