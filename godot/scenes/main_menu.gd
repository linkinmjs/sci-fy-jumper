extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var main_menu_music: AudioStreamPlayer = $MainMenuMusic
@onready var start_audio_effect: AudioStreamPlayer = $StartAudioEffect
var starting = false

func _ready() -> void:
	animation_player.play("idle")
	main_menu_music.finished.connect(_on_main_menu_music_finish)
	main_menu_music.play(0.0)

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("shoot") and !starting:
		starting = true
		start_audio_effect.play(0.0)
		animation_player.play("start")
		await main_menu_music.finished
		get_tree().change_scene_to_file("res://scenes/game.tscn")
	elif event.is_action_pressed("esc") and !starting:
		get_tree().quit()
		
func _on_main_menu_music_finish() -> void:
	main_menu_music.play(0.0)
