extends CharacterBody2D

enum PlayerState {
	IDLE,
	CHARGING,
	JUMPING,
	FALLING,
	SPLAT,
	WALKING,
	SHOOTING_IDLE,
	SHOOTING_WALKING,
	HITTED
}

var state : PlayerState = PlayerState.IDLE
var debug_visible: bool = false

# --- Movimiento ---
const GRAVITY := 800.0
const MAX_FALL_SPEED := 600.0
const MOVE_SPEED := 80.0

# --- Salto cargado ---
var jump_power: float = 0.0
const JUMP_POWER_STEP := 3.0
const MAX_JUMP_POWER := 2.0
const MIN_JUMP_POWER := 0.3
const MAX_JUMP_HEIGHT := 250.0

# --- Dirección / orientación ---
var direction: int = 0     # -1 (izq), 0 (neutral), 1 (der)
var facing: int = 1        # última orientación no nula; 1 der, -1 izq

# --- Suelo / colisiones ---
var is_grounded: bool = false
var landed_this_frame: bool = false
var impact_speed_y: float = 0.0
const SPLAT_IMPACT_THRESHOLD := 550.0

# --- Disparo ---
const SHOOT_DURATION: float = 1.0
var shoot_time_left: float = 0.0
var shoot_just: bool = false

# --- Daño / i-frames ---
@export var HURT_FREEZE_TIME: float = 0.30
@export var INVULN_TIME: float = 1.00
var invulnerable: bool = false

# --- Inputs ---
var left: bool = false
var right: bool = false
var jump: bool = false

# --- SFX ---
@onready var sfx_hit_hurt: AudioStreamPlayer = $SFX/HitHurt
@onready var sfx_jump: AudioStreamPlayer = $SFX/Jump
@onready var sfx_shoot_laser: AudioStreamPlayer = $SFX/ShootLaser
@onready var sfx_step: AudioStreamPlayer = $SFX/Step

var step_cd := 0.0
const STEP_INTERVAL := 0.55  # acá! ajustar al ritmo de la animación

# --- and the others :) ---
@export var laser_scene: PackedScene

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var splat_timer: Timer = $SplatTimer
@onready var debug_label: Label = $DebugLabel
@onready var laser_marker: Marker2D = $LaserMarker
@onready var hurt_freeze_timer: Timer = $HurtFreezeTimer
@onready var invuln_timer: Timer = $InvulnTimer

func _ready() -> void:
	splat_timer.timeout.connect(_on_splat_timer_timeout)
	hurt_freeze_timer.one_shot = true
	invuln_timer.one_shot = true
	hurt_freeze_timer.wait_time = HURT_FREEZE_TIME
	invuln_timer.wait_time = INVULN_TIME
	hurt_freeze_timer.timeout.connect(_on_hurt_freeze_timeout)
	invuln_timer.timeout.connect(_on_invuln_timeout)

	# Hurtbox: conectar ambas señales por compatibilidad (Area2D y PhysicsBody2D)
	hurtbox.area_entered.connect(_on_hurt_area_entered)
	hurtbox.body_entered.connect(_on_hurt_body_entered)

func _physics_process(delta: float) -> void:
	handle_input(delta)

	# Si estoy en un estado de suelo y NO hay piso, paso a FALLING antes de aplicar gravedad
	if state in [PlayerState.IDLE, PlayerState.WALKING, PlayerState.SHOOTING_IDLE, PlayerState.SHOOTING_WALKING] and not is_on_floor():
		state = PlayerState.FALLING

	# avanzar reloj de disparo
	if shoot_time_left > 0.0:
		shoot_time_left -= delta

	apply_gravity(delta)
	move_character()
	handle_state(delta)
	add_animation()
	update_debug_info()
	if is_grounded and absf(velocity.x) > 1.0 and state in [PlayerState.WALKING, PlayerState.SHOOTING_WALKING]:
		step_cd -= delta
		if step_cd <= 0.0:
			_play_sfx(sfx_step, 0.95, 1.05)
			step_cd = STEP_INTERVAL
	else:
		# reiniciamos el cooldown para que suenen pasos apenas vuelva a caminar
		step_cd = 0.0

func handle_input(delta: float) -> void:
	left  = Input.is_action_pressed("left")
	right = Input.is_action_pressed("right")
	jump  = Input.is_action_pressed("jump")
	shoot_just = Input.is_action_just_pressed("shoot")

	if Input.is_action_just_pressed("toggle_debug"):
		debug_visible = !debug_visible
		debug_label.visible = debug_visible

	if debug_visible and Input.is_action_just_pressed("left_click"):
		global_position = get_global_mouse_position()

	# Dirección (la leemos siempre para 'facing')
	if left:
		direction = -1
	elif right:
		direction = 1
	else:
		direction = 0
	if direction != 0:
		facing = direction

	# En SPLAT o HITTED no se procesa nada más
	if state in [PlayerState.SPLAT, PlayerState.HITTED]:
		return

	# --- DISPARO (en piso) ---
	if shoot_just and is_grounded and state in [PlayerState.IDLE, PlayerState.WALKING] and GameManager.actual_energy >= 0:
		shoot_laser()
		shoot_time_left = SHOOT_DURATION
		if direction != 0:
			state = PlayerState.SHOOTING_WALKING
			velocity.x = direction * MOVE_SPEED
		else:
			state = PlayerState.SHOOTING_IDLE
			velocity.x = 0
		return

	# Durante disparo
	if state == PlayerState.SHOOTING_IDLE:
		velocity.x = 0
		return
	if state == PlayerState.SHOOTING_WALKING:
		velocity.x = direction * MOVE_SPEED
		if direction == 0:
			state = PlayerState.SHOOTING_IDLE
		return

	# --- SALTO CARGADO ---
	if state in [PlayerState.IDLE, PlayerState.WALKING] and jump and is_grounded:
		state = PlayerState.CHARGING
		velocity.x = 0

	if state == PlayerState.CHARGING:
		velocity.x = 0
		if jump:
			jump_power += JUMP_POWER_STEP * delta
			if jump_power >= MAX_JUMP_POWER:
				start_jump()
		else:
			start_jump()
		return

	# --- CAMINAR / IDLE ---
	if is_grounded and state in [PlayerState.IDLE, PlayerState.WALKING]:
		if direction != 0:
			state = PlayerState.WALKING
			velocity.x = direction * MOVE_SPEED
		else:
			state = PlayerState.IDLE
			velocity.x = 0

func shoot_laser() -> void:
	_play_sfx(sfx_shoot_laser, 0.98, 1.02)
	GameManager.shoot_laser()
	var laser: Node = laser_scene.instantiate()
	var local_offset: Vector2 = laser_marker.global_position - global_position
	local_offset.x *= facing
	var spawn_pos: Vector2 = global_position + local_offset
	laser.global_position = spawn_pos
	if "dir" in laser:
		laser.dir = facing
	add_sibling(laser)

func start_jump() -> void:
	_play_sfx(sfx_jump, 0.96, 1.04)
	var power: float = clampf(jump_power, MIN_JUMP_POWER, MAX_JUMP_POWER)
	jump_power = 0.0
	state = PlayerState.JUMPING
	velocity.y = -MAX_JUMP_HEIGHT * power
	velocity.x = direction * 150.0

func apply_gravity(delta: float) -> void:
	# En HITTED no cae (freeze), en SPLAT tampoco (forzamos vel a 0 en handle_state)
	if state in [PlayerState.FALLING, PlayerState.JUMPING]:
		velocity.y += GRAVITY * delta
		if velocity.y > MAX_FALL_SPEED:
			velocity.y = MAX_FALL_SPEED

func move_character() -> void:
	var pre_velocity := velocity
	move_and_slide()

	var prev_grounded := is_grounded
	is_grounded = is_on_floor()
	landed_this_frame = (not prev_grounded) and is_grounded

	impact_speed_y = absf(pre_velocity.y)

	if not is_grounded and state not in [PlayerState.JUMPING, PlayerState.SPLAT, PlayerState.HITTED]:
		state = PlayerState.FALLING

	for i in range(get_slide_collision_count()):
		var collision := get_slide_collision(i)
		var normal := collision.get_normal()
		if not is_grounded and absf(normal.x) > 0.9:
			if absf(pre_velocity.x) < 1.0:
				velocity.x = 80.0 * -signf(normal.x)
			else:
				velocity.x = -pre_velocity.x * 0.5
			state = PlayerState.FALLING
			break

func handle_state(_delta: float) -> void:
	# HITTED (freeze total)
	if state == PlayerState.HITTED:
		velocity = Vector2.ZERO
		# (El paso a IDLE/WALKING ocurre en _on_hurt_freeze_timeout)
		return

	# Aire: JUMPING -> FALLING
	if state == PlayerState.JUMPING and velocity.y > 0.0:
		state = PlayerState.FALLING

	# Aterrizaje
	if landed_this_frame and state in [PlayerState.FALLING, PlayerState.JUMPING]:
		if impact_speed_y > SPLAT_IMPACT_THRESHOLD:
			state = PlayerState.SPLAT
			velocity = Vector2.ZERO
			if splat_timer:
				splat_timer.start()
		else:
			if direction != 0:
				state = PlayerState.WALKING
				velocity.x = direction * MOVE_SPEED
			else:
				state = PlayerState.IDLE
				velocity.x = 0.0

	# SPLAT: inmóvil y salida defensiva
	if state == PlayerState.SPLAT:
		velocity = Vector2.ZERO
		if not is_grounded:
			state = PlayerState.FALLING
			return
		if splat_timer == null or splat_timer.is_stopped():
			if direction != 0:
				state = PlayerState.WALKING
				velocity.x = direction * MOVE_SPEED
			else:
				state = PlayerState.IDLE
				velocity.x = 0.0
		return

	# Fin de disparo por tiempo
	if state in [PlayerState.SHOOTING_IDLE, PlayerState.SHOOTING_WALKING] and shoot_time_left <= 0.0:
		if is_grounded:
			if direction != 0:
				state = PlayerState.WALKING
				velocity.x = direction * MOVE_SPEED
			else:
				state = PlayerState.IDLE
				velocity.x = 0.0
		else:
			state = PlayerState.FALLING

func _on_splat_timer_timeout() -> void:
	if state == PlayerState.SPLAT:
		if is_grounded and direction != 0:
			state = PlayerState.WALKING
			velocity.x = direction * MOVE_SPEED
		else:
			state = PlayerState.IDLE
			velocity.x = 0.0

# ---------------------------
#   HURT / INVULNERABILITY
# ---------------------------
func _on_hurt_area_entered(_area: Area2D) -> void:
	_try_enter_hurt()

func _on_hurt_body_entered(_body: Node2D) -> void:
	_try_enter_hurt()

func _try_enter_hurt() -> void:
	# si está invulnerable, ignorar
	if invulnerable:
		return
	# Entrar a HITTED desde cualquier estado
	_play_sfx(sfx_hit_hurt, 0.95, 1.05)
	state = PlayerState.HITTED
	velocity = Vector2.ZERO
	# cancelar disparo en curso
	shoot_time_left = 0.0
	# arrancar freeze e invulnerabilidad
	invulnerable = true
	hurt_freeze_timer.start()
	invuln_timer.start()
	# parpadeo
	animated_sprite_2d.modulate.a = 0.6
	GameManager.hit_player()

func _on_hurt_freeze_timeout() -> void:
	# Termina el “parálisis”; elegir estado base
	if state == PlayerState.HITTED:
		if is_grounded and direction != 0:
			state = PlayerState.WALKING
			velocity.x = direction * MOVE_SPEED
		elif is_grounded:
			state = PlayerState.IDLE
			velocity.x = 0.0
		else:
			state = PlayerState.FALLING

func _on_invuln_timeout() -> void:
	# Fin de i-frames
	invulnerable = false
	animated_sprite_2d.modulate.a = 1.0

func _play_sfx(p: AudioStreamPlayer, pmin := 0.98, pmax := 1.02) -> void:
	if p == null: return
	p.pitch_scale = randf_range(pmin, pmax)  # leve variación para que no suene “igual”
	p.play()

func add_animation() -> void:
	# flip por orientación
	animated_sprite_2d.flip_h = (facing == -1)

	# parpadeo simple durante i-frames (opcional)
	if invulnerable:
		animated_sprite_2d.visible = (int(Time.get_ticks_msec() / 100) % 2) == 0
	else:
		animated_sprite_2d.visible = true

	match state:
		PlayerState.IDLE:
			animated_sprite_2d.play("idle")
		PlayerState.WALKING:
			animated_sprite_2d.play("walking")
		PlayerState.CHARGING:
			animated_sprite_2d.play("charging")
		PlayerState.JUMPING:
			animated_sprite_2d.play("jumping")
		PlayerState.FALLING:
			animated_sprite_2d.play("falling")
		PlayerState.SPLAT:
			animated_sprite_2d.play("splat")
		PlayerState.SHOOTING_IDLE:
			animated_sprite_2d.play("shooting_idle")
		PlayerState.SHOOTING_WALKING:
			animated_sprite_2d.play("shooting_walking")
		PlayerState.HITTED:
			animated_sprite_2d.play("hitted")
		_:
			pass

# --- Debug ---
func update_debug_info() -> void:
	var lines := []
	lines.append("STATE: %s" % PlayerState.keys()[state])
	lines.append("VEL: (%.1f, %.1f)" % [velocity.x, velocity.y])
	lines.append("POS: (%.0f, %.0f)" % [position.x, position.y])
	lines.append("GROUND: %s (landed:%s)" % [is_grounded, landed_this_frame])
	lines.append("IMPACT_Y: %.1f (thr:%.0f)" % [impact_speed_y, SPLAT_IMPACT_THRESHOLD])
	lines.append("DIR: %d  FACING: %d" % [direction, facing])
	lines.append("JUMP_PWR: %.2f" % jump_power)
	lines.append("SHOOT_T: %.2f  INVULN:%s" % [shoot_time_left, invulnerable])
	debug_label.text = "\n".join(lines)
