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
const SHOOT_DURATION: float = 1
var shoot_time_left: float = 0.0
var shoot_just: bool = false

# --- Inputs ---
var left: bool = false
var right: bool = false
var jump: bool = false

@export var laser_scene: PackedScene

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var splat_timer: Timer = $SplatTimer
@onready var debug_label: Label = $DebugLabel
@onready var laser_marker: Marker2D = $LaserMarker

func _ready() -> void:
	splat_timer.timeout.connect(_on_splat_timer_timeout)
	hurtbox.area_entered.connect(_on_area_entered)

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

func handle_input(delta: float) -> void:
	left  = Input.is_action_pressed("left")
	right = Input.is_action_pressed("right")
	jump  = Input.is_action_pressed("jump")
	shoot_just    = Input.is_action_just_pressed("shoot")

	if Input.is_action_just_pressed("toggle_debug"):
		debug_visible = !debug_visible
		debug_label.visible = debug_visible
	
	if debug_visible and Input.is_action_just_pressed("left_click"):
		global_position = get_global_mouse_position()
	
	# Dirección (la leemos siempre)
	if left:
		direction = -1
	elif right:
		direction = 1
	else:
		direction = 0

	# Actualizar "facing"
	if direction != 0:
		facing = direction

	# En SPLAT no se procesa nada más
	if state == PlayerState.SPLAT:
		return

	# --- DISPARO (en piso) ---
	# permitimos disparar estando quieto o caminando; ignoramos en el aire
	if shoot_just and is_grounded and state in [PlayerState.IDLE, PlayerState.WALKING]:
		shoot_laser()
		shoot_time_left = SHOOT_DURATION
		if direction != 0:
			state = PlayerState.SHOOTING_WALKING
			velocity.x = direction * MOVE_SPEED
		else:
			state = PlayerState.SHOOTING_IDLE
			velocity.x = 0
		return

	# Mientras dure el disparo, mantenemos la intención:
	if state == PlayerState.SHOOTING_IDLE:
		velocity.x = 0
		return
	if state == PlayerState.SHOOTING_WALKING:
		velocity.x = direction * MOVE_SPEED
		# si el jugador suelta dirección durante el disparo, queda en shooting_idle
		if direction == 0:
			state = PlayerState.SHOOTING_IDLE
		return

	# --- SALTO CARGADO ---
	# Inicio de carga (desde IDLE/WALKING en el piso)
	if state in [PlayerState.IDLE, PlayerState.WALKING] and jump and is_grounded:
		state = PlayerState.CHARGING
		velocity.x = 0  # frena inmediatamente

	# Mientras cargo, bloqueo lateral
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
	# 1) instanciar
	var laser: Node = laser_scene.instantiate()
	
	# 2) calcular posición de spawn usando el marker,
	#    pero espejando el offset cuando miramos a la izquierda.
	var local_offset: Vector2 = laser_marker.global_position - global_position
	local_offset.x *= facing  # espejo horizontal si facing = -1
	var spawn_pos: Vector2 = global_position + local_offset
	laser.global_position = spawn_pos
	
	# 3) pasar dirección al láser (1 der, -1 izq) y orientar su sprite
	#    (usa el campo "dir" que agregamos en el láser)
	if "dir" in laser:
		laser.dir = facing
	
	# 4) agregar al mismo padre que el player (hermano en la escena)
	add_sibling(laser)

func start_jump() -> void:
	var power: float = clampf(jump_power, MIN_JUMP_POWER, MAX_JUMP_POWER)
	jump_power = 0.0
	state = PlayerState.JUMPING
	velocity.y = -MAX_JUMP_HEIGHT * power
	velocity.x = direction * 150.0  # poné 0 si querés salto vertical puro

func apply_gravity(delta: float) -> void:
	if state in [PlayerState.FALLING, PlayerState.JUMPING]:
		velocity.y += GRAVITY * delta
		if velocity.y > MAX_FALL_SPEED:
			velocity.y = MAX_FALL_SPEED

func move_character() -> void:
	var pre_velocity := velocity  # para medir impacto
	move_and_slide()

	# piso actual y detección de aterrizaje
	var prev_grounded := is_grounded
	is_grounded = is_on_floor()
	landed_this_frame = (not prev_grounded) and is_grounded

	# velocidad de impacto vertical (antes de colisionar)
	impact_speed_y = absf(pre_velocity.y)

	# si quedé en el aire y no estoy en JUMPING ni SPLAT, aseguro FALLING
	if not is_grounded and state not in [PlayerState.JUMPING, PlayerState.SPLAT]:
		state = PlayerState.FALLING

	# rebote lateral en el aire
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

func handle_state(delta: float) -> void:
	if state == PlayerState.HITTED:
		velocity.x = 0.0
		velocity.y = 0.0
		await get_tree().create_timer(1).timeout
		state = PlayerState.IDLE
		
	# Aire: JUMPING -> FALLING
	if state == PlayerState.JUMPING and velocity.y > 0.0:
		state = PlayerState.FALLING

	# Aterrizaje: solo el frame que tocamos suelo
	if landed_this_frame and state in [PlayerState.FALLING, PlayerState.JUMPING]:
		if impact_speed_y > SPLAT_IMPACT_THRESHOLD:
			state = PlayerState.SPLAT
			velocity.x = 0.0
			velocity.y = 0.0
			if splat_timer:
				splat_timer.start()
		else:
			# si venía disparando en el aire, al caer lo ignoramos y volvemos a base
			if direction != 0:
				state = PlayerState.WALKING
				velocity.x = direction * MOVE_SPEED
			else:
				state = PlayerState.IDLE
				velocity.x = 0.0

	# BLOQUE SPLAT: inmóvil y salida defensiva
	if state == PlayerState.SPLAT:
		velocity.x = 0.0
		velocity.y = 0.0
		if not is_grounded:
			state = PlayerState.FALLING
			return
		# si terminó el timer, salir según input
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

func add_animation() -> void:
	# flip por orientación
	animated_sprite_2d.flip_h = (facing == -1)

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

func _on_area_entered(area: Area2D) -> void:
	#await get_tree().create_timer(1).timeout
	state = PlayerState.HITTED

func _on_splat_timer_timeout() -> void:
	# salida inmediata de SPLAT (handle_state también contempla salida defensiva)
	if state == PlayerState.SPLAT:
		if is_grounded and direction != 0:
			state = PlayerState.WALKING
			velocity.x = direction * MOVE_SPEED
		else:
			state = PlayerState.IDLE
			velocity.x = 0.0

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
	lines.append("SHOOT_T: %.2f" % shoot_time_left)
	debug_label.text = "\n".join(lines)
