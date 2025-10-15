extends Control

@onready var tile_map_layer: TileMapLayer = $TileMapLayer
@onready var area_2d: Area2D = $Area2D
@onready var tutorial_first_time: Control = $"."
@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	tile_map_layer.hide()
	area_2d.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	pass

func _on_body_entered(_body: Node2D) -> void:
	if GameManager.show_tutorial:
		
		tutorial_first_time.modulate = Color.TRANSPARENT
		create_tween().tween_property(tutorial_first_time, "modulate", Color.WHITE, 0.3)
		
		tile_map_layer.show()
		animation_player.play("turn_off")
		GameManager.show_tutorial = false
		
