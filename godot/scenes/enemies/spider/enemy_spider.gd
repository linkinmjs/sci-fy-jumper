extends CharacterBody2D

@onready var player_node: CharacterBody2D = get_parent().get_node("Player")
@onready var sprite: Node2D = $pivot
@onready var animated_sprite_2d: AnimatedSprite2D = $pivot/AnimatedSprite2D

@onready var leftray: RayCast2D = $leftray
@onready var rightray: RayCast2D = $rightray
@onready var lefttwallray: RayCast2D = $lefttwallray
@onready var rightwallray: RayCast2D = $rightwallray
@onready var hurtbox: Area2D = $Hurtbox
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

@export var life: int = 2
@export_range(-1, 1) var dir: int = 1

var speed: float = 35.0
var gravity: float = 15.0
var hitted: bool = false
var alive: bool = true

func _ready() -> void:
	hurtbox.area_entered.connect(_on_area_entered)
	if dir == 0:
		dir = 1
	# flip inicial
	sprite.scale.x = absf(sprite.scale.x) * (1 if dir == 1 else -1)

func _physics_process(delta: float) -> void:
	if not alive:
		return
	
	if hitted:
		animated_sprite_2d.play("hitted")
		velocity = Vector2.ZERO
		return

	if dir == 1 and (not rightray.is_colliding() or rightwallray.is_colliding()):
		sprite.scale.x = -absf(sprite.scale.x)
		dir = 0
		_wait_dir_change(-1)
	elif dir == -1 and (not leftray.is_colliding() or lefttwallray.is_colliding()):
		sprite.scale.x = absf(sprite.scale.x)
		dir = 0
		_wait_dir_change(1)
	
	velocity.x = lerp(velocity.x, dir * speed, 10.0 * delta)
	velocity.y += gravity
	move_and_slide()

func _wait_dir_change(desire_dir: int) -> void:
	animated_sprite_2d.play("idle")
	await get_tree().create_timer(1).timeout
	animated_sprite_2d.play("walking")
	await get_tree().create_timer(0.3).timeout
	dir = desire_dir

func _on_area_entered(area: Area2D) -> void:
	if not alive:
		return
	life -= 1
	if life <= 0:
		die()
		return
	
	var actual_animation := animated_sprite_2d.animation
	hitted = true
	await get_tree().create_timer(1).timeout
	animated_sprite_2d.play(actual_animation)
	hitted = false

func die() -> void:
	alive = false
	hitted = false
	velocity = Vector2.ZERO
	animated_sprite_2d.play("dying")
	
	# --- DESACTIVAR COLISIONES SIN ROMPER EL IMPACTO ACTUAL ---
	# apagar hurtbox (deja de hacer daño)
	hurtbox.set_deferred("monitoring", false)
	hurtbox.set_deferred("monitorable", false)
	# quitar layer/mask del cuerpo y deshabilitar su shape
	set_deferred("collision_layer", 0)
	set_deferred("collision_mask", 0)
	collision_shape_2d.set_deferred("disabled", true)
	
	# cuando termina la animación, eliminar
	await animated_sprite_2d.animation_finished
	queue_free()
