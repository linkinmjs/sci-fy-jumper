extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
const GAME_SCENE: PackedScene = preload("res://scenes/game.tscn")

func _ready() -> void:
	animation_player.play("idle")

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		get_tree().change_scene_to_file("res://scenes/game.tscn")
