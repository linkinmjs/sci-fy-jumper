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
}

var state : PlayerState = PlayerState.IDLE
var debug_visible: bool = true

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

# --- Dirección ---
var direction: int = 0  # -1 (izq), 0 (neutral), 1 (der)

# --- Estados / piso ---
var is_grounded: bool = false
var landed_this_frame: bool = false
var impact_speed_y: float = 0.0
const SPLAT_IMPACT_THRESHOLD := 550.0

# --- Inputs ---
var left: bool = false
var right: bool = false
var jump: bool = false

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var splat_timer: Timer = $SplatTimer
@onready var debug_label: Label = $DebugLabel


func _ready() -> void:
	splat_timer.timeout.connect(_on_splat_timer_timeout)

func _physics_process(delta: float) -> void:
	handle_input(delta)

	# Si estoy en un estado de suelo y NO hay piso, paso a FALLING antes de aplicar gravedad
	if state in [PlayerState.IDLE, PlayerState.WALKING] and not is_on_floor():
		state = PlayerState.FALLING

	apply_gravity(delta)
	move_character()
	handle_state(delta)
	add_animation()
	update_debug_info()

func handle_input(delta: float) -> void:
	left = Input.is_action_pressed("left")
	right = Input.is_action_pressed("right")
	jump = Input.is_action_pressed("jump")

	if Input.is_action_just_pressed("toggle_debug"):
		debug_visible = !debug_visible
		debug_label.visible = debug_visible

	# Dirección (la leemos siempre, incluso en SPLAT, para saber hacia dónde ir al salir)
	if left:
		direction = -1
	elif right:
		direction = 1
	else:
		direction = 0

	# En SPLAT no se procesa movimiento ni carga de salto
	if state == PlayerState.SPLAT:
		return

	# Inicio de carga de salto (desde IDLE o WALKING en el piso)
	if state in [PlayerState.IDLE, PlayerState.WALKING] and jump and is_grounded:
		state = PlayerState.CHARGING
		velocity.x = 0  # frena inmediatamente

	# Mientras cargo el salto, bloqueo movimiento lateral
	if state == PlayerState.CHARGING:
		velocity.x = 0
		if jump:
			jump_power += JUMP_POWER_STEP * delta
			if jump_power >= MAX_JUMP_POWER:
				start_jump()
		else:
			start_jump()
		return

	# Caminar / Idle (solo si estoy en el piso)
	if is_grounded and state in [PlayerState.IDLE, PlayerState.WALKING]:
		if direction != 0:
			state = PlayerState.WALKING
			velocity.x = direction * MOVE_SPEED
		else:
			state = PlayerState.IDLE
			velocity.x = 0

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
	var pre_velocity := velocity  # velocidad ANTES de moverse (para medir impacto)
	move_and_slide()

	# piso actual y detección de aterrizaje
	var prev_grounded := is_grounded
	is_grounded = is_on_floor()
	landed_this_frame = (not prev_grounded) and is_grounded

	# velocidad de impacto vertical (lo que traías antes de colisionar)
	impact_speed_y = absf(pre_velocity.y)

	# Si quedé en el aire y no estoy en JUMPING ni SPLAT (p.ej. me caí de un borde), aseguro FALLING
	if not is_grounded and state != PlayerState.JUMPING and state != PlayerState.SPLAT:
		state = PlayerState.FALLING

	# Rebote lateral en el aire
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
	# Aire: JUMPING -> FALLING
	if state == PlayerState.JUMPING and velocity.y > 0.0:
		state = PlayerState.FALLING

	# Aterrizaje: solo reaccionar el frame en que tocamos suelo
	if landed_this_frame and state in [PlayerState.FALLING, PlayerState.JUMPING]:
		if impact_speed_y > SPLAT_IMPACT_THRESHOLD:
			state = PlayerState.SPLAT
			velocity.x = 0.0
			velocity.y = 0.0
			if splat_timer:
				splat_timer.start()
		else:
			if direction != 0:
				state = PlayerState.WALKING
				velocity.x = direction * MOVE_SPEED
			else:
				state = PlayerState.IDLE
				velocity.x = 0.0

	# Mientras esté en SPLAT: inmóvil; si pierde piso por algo, vuelve a caer
	if state == PlayerState.SPLAT:
		velocity.x = 0.0
		velocity.y = 0.0
		if not is_grounded:
			state = PlayerState.FALLING
		return

func _on_splat_timer_timeout() -> void:
	# Salir de SPLAT según input y piso
	if state == PlayerState.SPLAT:
		if is_grounded and direction != 0:
			state = PlayerState.WALKING
			velocity.x = direction * MOVE_SPEED
		else:
			state = PlayerState.IDLE
			velocity.x = 0.0

func add_animation() -> void:		
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
		_:
			pass

# Debug
func update_debug_info() -> void:
	var lines := []
	lines.append("STATE: %s" % PlayerState.keys()[state])
	lines.append("VEL: (%.1f, %.1f)" % [velocity.x, velocity.y])
	lines.append("POS: (%.0f, %.0f)" % [position.x, position.y])
	lines.append("GROUND: %s (landed:%s)" % [is_grounded, landed_this_frame])
	lines.append("IMPACT_Y: %.1f (thr:%.0f)" % [impact_speed_y, SPLAT_IMPACT_THRESHOLD])
	lines.append("DIR: %d" % direction)
	lines.append("JUMP_PWR: %.2f" % jump_power)
	debug_label.text = "\n".join(lines)
