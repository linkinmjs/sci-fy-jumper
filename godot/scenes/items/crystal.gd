extends AnimatedSprite2D

@onready var area_2d: Area2D = $Area2D
@onready var audio_stream_player: AudioStreamPlayer = $AudioStreamPlayer
@onready var crystal: AnimatedSprite2D = $"."

func _ready() -> void:
	area_2d.body_entered.connect(_on_body_entered)
	
func _on_body_entered(_body: Node2D) -> void:
	GameManager.add_score(10000)
	audio_stream_player.play()
	create_tween().tween_property(crystal, "modulate", Color.TRANSPARENT, 0.5)
	create_tween().tween_property(crystal, "global_position", global_position + Vector2(0.0,-20.0), 0.5)
	await audio_stream_player.finished
	queue_free()
