extends Node

var actual_life: int = 10
var actual_energy: int = 5
var actual_level: int = 1

signal player_is_hitted
signal laser_is_shooted

func hit_player() -> void:
	emit_signal("player_is_hitted")
	actual_life -= 1
	
func shoot_laser() -> void:
	emit_signal("laser_is_shooted")
	actual_energy -= 1
