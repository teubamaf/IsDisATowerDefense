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

	# Obtenir une position de spawn aux bords des zones débloquées
	var spawn_pos = get_edge_spawn_position()
	if spawn_pos == Vector2.ZERO:
		# Fallback: position aléatoire autour du château si aucune zone trouvée
		var angle = randf() * TAU
		spawn_pos = castle_position + Vector2(cos(angle), sin(angle)) * spawn_distance

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

func get_edge_spawn_position() -> Vector2:
	# Récupérer le ChunkGrid pour connaître les zones débloquées
	var chunk_grid = get_tree().get_first_node_in_group("chunk_grid")
	if not chunk_grid:
		# Chercher dans la scène
		chunk_grid = get_node_or_null("/root/Game/ChunkGrid")

	if not chunk_grid or not chunk_grid.has_method("world_to_chunk"):
		return Vector2.ZERO

	# Récupérer tous les chunks débloqués
	var unlocked_chunks = chunk_grid.chunks_unlocked.keys()
	if unlocked_chunks.is_empty():
		return Vector2.ZERO

	# Trouver les bords réels (les côtés de chunks qui touchent des chunks non débloqués)
	var spawn_points: Array[Dictionary] = []

	for chunk_pos in unlocked_chunks:
		var chunk_world_pos = chunk_grid.chunk_to_world(chunk_pos)
		var chunk_size = chunk_grid.CHUNK_SIZE
		var chunk_half_size = chunk_size / 2.0

		# Vérifier chaque côté du chunk
		var neighbors = [
			{"dir": Vector2i(1, 0), "side": "right"},   # Droite
			{"dir": Vector2i(-1, 0), "side": "left"},   # Gauche
			{"dir": Vector2i(0, 1), "side": "bottom"},  # Bas
			{"dir": Vector2i(0, -1), "side": "top"}     # Haut
		]

		for neighbor_info in neighbors:
			var neighbor_pos = chunk_pos + neighbor_info["dir"]

			# Si le voisin n'est pas débloqué, ce côté est un bord
			if not chunk_grid.is_chunk_unlocked(neighbor_pos):
				var edge_info = {
					"chunk_pos": chunk_pos,
					"chunk_world_pos": chunk_world_pos,
					"side": neighbor_info["side"],
					"half_size": chunk_half_size
				}
				spawn_points.append(edge_info)

	if spawn_points.is_empty():
		# Fallback: tous les chunks sont intérieurs
		var random_chunk = unlocked_chunks[randi() % unlocked_chunks.size()]
		var chunk_world_pos = chunk_grid.chunk_to_world(random_chunk)
		var chunk_size = chunk_grid.CHUNK_SIZE
		var offset_x = randf_range(-chunk_size * 0.4, chunk_size * 0.4)
		var offset_y = randf_range(-chunk_size * 0.4, chunk_size * 0.4)
		return chunk_world_pos + Vector2(offset_x, offset_y)

	# Choisir un bord aléatoire
	var edge = spawn_points[randi() % spawn_points.size()]
	var spawn_pos = edge["chunk_world_pos"]
	var half_size = edge["half_size"]

	# Placer l'ennemi sur le bord exact avec une variation le long du bord
	match edge["side"]:
		"right":
			spawn_pos.x += half_size
			spawn_pos.y += randf_range(-half_size * 0.8, half_size * 0.8)
		"left":
			spawn_pos.x -= half_size
			spawn_pos.y += randf_range(-half_size * 0.8, half_size * 0.8)
		"bottom":
			spawn_pos.y += half_size
			spawn_pos.x += randf_range(-half_size * 0.8, half_size * 0.8)
		"top":
			spawn_pos.y -= half_size
			spawn_pos.x += randf_range(-half_size * 0.8, half_size * 0.8)

	return spawn_pos
