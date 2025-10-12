extends AnimatedSprite2D

var impacted = false
var dir: int = 1  # 1 derecha, -1 izquierda

@export var speed: float = 20.0
@onready var impact_area: Area2D = $ImpactArea
@onready var onscreen: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D


func _ready() -> void:
	impact_area.body_entered.connect(_on_body_entered)
	impact_area.area_entered.connect(_on_area_entered)
	onscreen.screen_exited.connect(queue_free)
	flip_h = (dir < 0)

func _process(delta: float) -> void:
	animate()
	if impacted:
		return
	global_position.x += dir * speed * delta


func _on_body_entered(body: Node2D) -> void:
	if impacted: return
	impacted = true
	await get_tree().create_timer(1).timeout
	queue_free()

func _on_area_entered(area: Area2D) -> void:
	if impacted: return
	impacted = true
	await get_tree().create_timer(1).timeout
	queue_free()


func animate() -> void:
	if impacted:
		play("impact")
	else:
		play("idle")
