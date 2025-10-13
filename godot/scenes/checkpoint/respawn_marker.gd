extends Marker2D

@onready var on_screen: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
var seen := false

func _ready() -> void:
	GameManager.register_respawn(global_position)
	on_screen.screen_entered.connect(func(): seen = true)
	on_screen.screen_exited.connect(_on_screen_exited)

func _on_screen_exited() -> void:
	# solo borrar si alguna vez estuvo visible
	if seen:
		GameManager.unregister_respawn(global_position)
		queue_free()

func _exit_tree() -> void:
	# por si se descarga la escena del nivel
	GameManager.unregister_respawn(global_position)
