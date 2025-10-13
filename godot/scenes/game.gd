extends Node2D

@export var start_level_scene: PackedScene
@export var end_level_scene: PackedScene
@export var level_scenes: Array[PackedScene]
@export var test_level_scenes: Array[PackedScene]
@export var level_number: int = 1

@onready var complete_level_node: Node2D = $Level
@onready var path_camera: Path2D = $PathCamera
@onready var game_music: AudioStreamPlayer = $Audios/GameMusic

const LEVEL_WIDTH: int = 576

func _ready() -> void:
	level_number = GameManager.actual_level
	game_music.play(0.0)
	build_level(level_number)

func build_level(level_num: int) -> void:
	# 1) limpiar nivel
	for child in complete_level_node.get_children():
		child.queue_free()
		
	# 2) seleccionar escenas
	# Nota: con cantidad acorde al nivel
	var available: int = test_level_scenes.size()
	var pick_count: int = clamp(level_num + 1, 0, available)
	
	# 3) obtener escenas
	var pool: Array[PackedScene] = test_level_scenes.duplicate()
	pool.shuffle()
	var selected: Array[PackedScene]
	for i in range(pick_count):
		selected.append(pool[i])
	
	# 4) armar secuencia
	var sequence: Array[PackedScene] = []
	sequence.append(start_level_scene)
	sequence.append_array(selected)
	sequence.append(end_level_scene)
	
	# 5) instanciar niveles
	var lvl_scene_position = 0
	for chunk in sequence:
		var lvl_scene: TileMapLayer = chunk.instantiate()
		lvl_scene.position.x = lvl_scene_position * LEVEL_WIDTH
		complete_level_node.add_child(lvl_scene)
		lvl_scene_position += 1
	
	# 6) ajustar path camera
	var last_point_position_x = (lvl_scene_position - 1) * LEVEL_WIDTH
	var last_point_position = Vector2(last_point_position_x,0)
	path_camera.curve.set_point_position(1,last_point_position)
