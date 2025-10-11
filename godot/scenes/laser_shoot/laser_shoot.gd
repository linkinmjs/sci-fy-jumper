extends AnimatedSprite2D

@onready var impact_area: Area2D = $ImpactArea
var impacted = false

func _ready() -> void:
	impact_area.body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	animate()
	if not impacted:
		global_position.x += delta + 10

func _on_body_entered(body: Node2D) -> void:
	print("Entró body al impacto %s" % body.name)
	impacted = true
	await get_tree().create_timer(1).timeout
	queue_free()

func animate() -> void:
	if impacted:
		play("impact")
	else:
		play("idle")
