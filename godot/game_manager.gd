extends Node

var actual_life: int = 10
var actual_energy: int = 5
var actual_level: int = 1

var respawns: Array[Vector2] = []

signal player_is_hitted
signal laser_is_shooted

func hit_player() -> void:
	emit_signal("player_is_hitted")
	actual_life -= 1

func shoot_laser() -> void:
	emit_signal("laser_is_shooted")
	actual_energy -= 1

func register_respawn(p: Vector2) -> void:
	respawns.append(p)
	
func unregister_respawn(p: Vector2) -> void:
	var i := respawns.find(p)
	if i != -1:
		respawns.remove_at(i)

func first_respawn() -> Vector2:
	if respawns.size() > 0:
		return respawns[0] 
	else:
		return Vector2.ZERO
