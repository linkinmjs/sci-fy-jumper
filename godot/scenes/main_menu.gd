extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var main_menu_music: AudioStreamPlayer = $MainMenuMusic
@onready var start_audio_effect: AudioStreamPlayer = $StartAudioEffect


func _ready() -> void:
	animation_player.play("idle")
	main_menu_music.play(0.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot"):
		start_audio_effect.play(0.0)
		animation_player.play("start")
		await main_menu_music.finished
		get_tree().change_scene_to_file("res://scenes/game.tscn")
