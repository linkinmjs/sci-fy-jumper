extends Node2D

@export var camera: Camera2D
@export var noise: FastNoiseLite
@export var intensity: float = 100.0
@export var max_intensity: float = 200.0
var current_intensity: float = 0.0
var shake_time_duration: float = 0.8
var shake_time_left: float = 0.0
var intensity_tween: Tween
var time_since_ready: float = 0.0
@export var frequency: float = 10.0

func _ready() -> void:
	GameManager.player_is_splatted.connect(func(): self.shake(shake_time_duration))

func _process(delta: float) -> void:
	time_since_ready += delta
	var noise_value_x = noise.get_noise_1d(time_since_ready * frequency)
	var noise_value_y = noise.get_noise_1d(time_since_ready * frequency)
	shake_time_left = move_toward(shake_time_left,0.0,delta)
	
	if shake_time_left > 0.0:
		camera.offset = Vector2(
			current_intensity * noise_value_x,
			current_intensity * noise_value_y
		)
	else:
		camera.offset = Vector2.ZERO

func shake(duration: float, shake_intensity: float = intensity) -> void:
	shake_time_left = duration
	current_intensity += shake_intensity
	current_intensity = min(current_intensity, max_intensity)
	
	if intensity_tween and intensity_tween.is_valid():
		intensity_tween.kill()
	intensity_tween = create_tween()
	intensity_tween.tween_property(self, "current_intensity", 0.0, duration)
