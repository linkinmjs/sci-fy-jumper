extends Node

var actual_life: int = 10
var actual_energy: int = 5
var actual_level: int = 1

var score: int = 0
var can_add_scores: bool = false

var respawns: Array[Vector2] = []

var show_tutorial: bool = true

signal player_is_hitted
signal laser_is_shooted
signal adding_score
signal restart_game
signal changel_level

func hit_player() -> void:
	if actual_life == 1:
		get_tree().change_scene_to_file("res://scenes/game_over_menu.tscn")
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

func add_score(points: int) -> void:
	if not can_add_scores:
		return
	score += points
	emit_signal("adding_score")

func change_next_level() -> void:
	actual_level += 1
	actual_energy = 5
	actual_life = 10
	get_tree().reload_current_scene()
	emit_signal("changel_level")
	pass

func restart_stats() -> void:
	emit_signal("restart_game")
	actual_life = 10
	actual_energy = 5
	actual_level = 1
	show_tutorial = true
	score = 0
