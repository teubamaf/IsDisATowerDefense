extends Node2D

# Préchargement de la scène ennemie
@export var enemy_scene: PackedScene
@export var spawn_distance: float = 400.0  # Distance du château pour spawn

@onready var game_manager = GameManager
var castle_position: Vector2 = Vector2.ZERO
var active_enemies: Array[Node2D] = []

func _ready():
	# Connecter aux signaux du GameManager
	game_manager.wave_started.connect(_on_wave_started)

	# Trouver le château
	await get_tree().process_frame
	var castle = get_tree().get_first_node_in_group("castle")
	if castle:
		castle_position = castle.global_position

func _process(_delta: float):
	# Vérifier si tous les ennemis sont morts
	if game_manager.wave_in_progress:
		clean_dead_enemies()
		if active_enemies.is_empty():
			game_manager.complete_wave()

func _on_wave_started(wave_num: int):
	spawn_wave(wave_num)

func spawn_wave(wave_num: int):
	active_enemies.clear()

	# Calculer le nombre d'ennemis selon la vague
	var enemy_count = 5 + (wave_num * 3)
	var spawn_delay = 0.5  # Délai entre chaque spawn

	for i in range(enemy_count):
		await get_tree().create_timer(spawn_delay).timeout
		spawn_enemy(wave_num)

func spawn_enemy(wave_num: int):
	if not enemy_scene:
		print("Erreur: Scène ennemie non définie !")
		return

	# Créer l'ennemi
	var enemy = enemy_scene.instantiate()

	# Position aléatoire autour du château
	var angle = randf() * TAU
	var spawn_pos = castle_position + Vector2(cos(angle), sin(angle)) * spawn_distance

	enemy.global_position = spawn_pos

	# Augmenter les stats selon la vague
	if enemy.has_method("scale_for_wave"):
		enemy.scale_for_wave(wave_num)
	else:
		# Scaling par défaut
		enemy.max_hp *= (1.0 + wave_num * 0.2)
		enemy.current_hp = enemy.max_hp
		enemy.damage *= (1.0 + wave_num * 0.1)
		enemy.gold_reward *= (1.0 + wave_num * 0.3)

	# Ajouter au jeu
	add_child(enemy)
	active_enemies.append(enemy)

func clean_dead_enemies():
	# Supprimer les ennemis morts de la liste
	for enemy in active_enemies:
		if not is_instance_valid(enemy):
			active_enemies.erase(enemy)

func get_enemy_count() -> int:
	clean_dead_enemies()
	return active_enemies.size()
