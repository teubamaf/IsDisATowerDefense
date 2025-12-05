extends Node2D

# Spawn automatique de ressources collectables autour du château

@export var resource_scene: PackedScene
@export var spawn_radius_min: float = 150.0
@export var spawn_radius_max: float = 350.0
@export var spawn_interval: float = 5.0  # Spawn toutes les 5 secondes
@export var max_resources: int = 10

@onready var spawn_timer = $SpawnTimer
var castle_position: Vector2 = Vector2.ZERO
var active_resources: Array[Node] = []

func _ready():
	# Trouver le château
	await get_tree().process_frame
	var castle = get_tree().get_first_node_in_group("castle")
	if castle:
		castle_position = castle.global_position

	# Configuration du timer
	spawn_timer.wait_time = spawn_interval
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	spawn_timer.start()

	# Spawn initial
	for i in range(3):
		spawn_resource()

func _on_spawn_timer_timeout():
	clean_destroyed_resources()

	if active_resources.size() < max_resources:
		spawn_resource()

func spawn_resource():
	if not resource_scene:
		print("Erreur: Scène de ressource non définie !")
		return

	# Position aléatoire autour du château
	var angle = randf() * TAU
	var distance = randf_range(spawn_radius_min, spawn_radius_max)
	var spawn_pos = castle_position + Vector2(cos(angle), sin(angle)) * distance

	# Créer la ressource
	var resource = resource_scene.instantiate()
	resource.global_position = spawn_pos

	# Type aléatoire
	var random_type = randi() % 3
	if "resource_type" in resource:
		resource.resource_type = random_type

	add_child(resource)
	active_resources.append(resource)

func clean_destroyed_resources():
	for resource in active_resources:
		if not is_instance_valid(resource):
			active_resources.erase(resource)
