extends CharacterBody2D

@onready var player_node: CharacterBody2D = get_parent().get_node("Player")
@onready var sprite: Node2D = $pivot

@onready var leftray: RayCast2D = $leftray
@onready var rightray: RayCast2D = $rightray
@onready var lefttwallray: RayCast2D = $lefttwallray
@onready var rightwallray: RayCast2D = $rightwallray

@export_range(-1, 1) var dir: int = 1

var speed: float = 35.0
var gravity: int = 15

func _ready() -> void:
	if dir == 0:
		dir = 1
		sprite.flip_h = false if dir == 1 else true
		
func _physics_process(delta: float) -> void:
	if dir == 1 and (!rightray.is_colliding() or rightwallray.is_colliding()):
		sprite.scale.x = -abs(1)
		dir = 0
		_wait_dir_change(-1)
	if dir == -1 and (!leftray.is_colliding() or lefttwallray.is_colliding()):
		sprite.scale.x = abs(1)
		dir = 0
		_wait_dir_change(1)
	
	velocity.x = lerp(velocity.x, dir * speed, 10.0 * delta)
	velocity.y += gravity
	move_and_slide()

func _wait_dir_change(desire_dir: int) -> void:
	await get_tree().create_timer(0.5).timeout
	dir = desire_dir
