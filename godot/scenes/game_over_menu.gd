extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer

func _ready() -> void:
	animation_player.play("idle")
	audio_stream_player.play(0.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
