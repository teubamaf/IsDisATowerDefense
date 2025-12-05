extends Node2D

# Système de grille pour l'expansion du territoire

const CHUNK_SIZE = 200  # Taille d'un chunk en pixels
const MAX_GRID_SIZE = 11  # Grille 11x11 (le château au centre 5,5)

# Coûts d'achat
@export var chunk_gold_cost: float = 100.0
@export var chunk_wood_cost: float = 50.0

# Grille de chunks (true = débloqué, false = verrouillé)
var chunks_unlocked: Dictionary = {}
var chunk_visuals: Dictionary = {}  # Stocke les sprites/cadres visuels

# Position centrale (le château)
var center_chunk: Vector2i = Vector2i(5, 5)

# Références visuelles
@onready var chunk_container = $ChunkContainer

func _ready():
	# Débloquer le chunk central
	unlock_chunk(center_chunk, true)  # Gratuit pour le départ

	# Créer les visuels pour tous les chunks
	create_chunk_visuals()

func create_chunk_visuals():
	for x in range(MAX_GRID_SIZE):
		for y in range(MAX_GRID_SIZE):
			var chunk_pos = Vector2i(x, y)
			create_chunk_visual(chunk_pos)

func create_chunk_visual(chunk_pos: Vector2i):
	# Créer un cadre visuel pour le chunk
	var chunk_frame = ColorRect.new()
	chunk_frame.custom_minimum_size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
	chunk_frame.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)

	# Position dans le monde
	var world_pos = chunk_to_world(chunk_pos)
	chunk_frame.position = world_pos - Vector2(CHUNK_SIZE / 2, CHUNK_SIZE / 2)

	# Couleur selon l'état
	if is_chunk_unlocked(chunk_pos):
		chunk_frame.color = Color(0.2, 0.6, 0.2, 0.3)  # Vert transparent
	else:
		chunk_frame.color = Color(0.1, 0.1, 0.1, 0.5)  # Gris foncé

	# Bordure
	var border = ReferenceRect.new()
	border.border_color = Color.WHITE
	border.border_width = 2.0
	border.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
	chunk_frame.add_child(border)

	# Rendre clickable si adjacente à un chunk débloqué
	if can_unlock_chunk(chunk_pos):
		var button = Button.new()
		button.custom_minimum_size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
		button.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
		button.flat = true
		button.text = "Acheter\n%d Or\n%d Bois" % [chunk_gold_cost, chunk_wood_cost]
		button.pressed.connect(func(): try_unlock_chunk(chunk_pos))
		chunk_frame.add_child(button)

	chunk_container.add_child(chunk_frame)
	chunk_visuals[chunk_pos] = chunk_frame

func chunk_to_world(chunk_pos: Vector2i) -> Vector2:
	# Convertit une position de chunk en position monde
	return Vector2(
		(chunk_pos.x - center_chunk.x) * CHUNK_SIZE,
		(chunk_pos.y - center_chunk.y) * CHUNK_SIZE
	)

func world_to_chunk(world_pos: Vector2) -> Vector2i:
	# Convertit une position monde en position de chunk
	return Vector2i(
		int(world_pos.x / CHUNK_SIZE) + center_chunk.x,
		int(world_pos.y / CHUNK_SIZE) + center_chunk.y
	)

func is_chunk_unlocked(chunk_pos: Vector2i) -> bool:
	return chunks_unlocked.get(chunk_pos, false)

func can_unlock_chunk(chunk_pos: Vector2i) -> bool:
	# Vérifier si le chunk n'est pas déjà débloqué
	if is_chunk_unlocked(chunk_pos):
		return false

	# Vérifier si au moins un chunk adjacent est débloqué
	var adjacent_positions = [
		chunk_pos + Vector2i(1, 0),
		chunk_pos + Vector2i(-1, 0),
		chunk_pos + Vector2i(0, 1),
		chunk_pos + Vector2i(0, -1)
	]

	for adj_pos in adjacent_positions:
		if is_chunk_unlocked(adj_pos):
			return true

	return false

func try_unlock_chunk(chunk_pos: Vector2i):
	if not can_unlock_chunk(chunk_pos):
		print("Ce chunk ne peut pas être débloqué pour le moment")
		return

	if GameManager.spend_resources(chunk_gold_cost, chunk_wood_cost, 0):
		unlock_chunk(chunk_pos, false)
		print("Chunk débloqué à ", chunk_pos)
	else:
		print("Ressources insuffisantes pour acheter ce chunk")

func unlock_chunk(chunk_pos: Vector2i, free: bool):
	chunks_unlocked[chunk_pos] = true

	# Mettre à jour les visuels
	refresh_chunk_visuals()

	# Générer du contenu dans le chunk (ressources naturelles, etc.)
	spawn_chunk_content(chunk_pos)

func refresh_chunk_visuals():
	# Nettoyer et recréer les visuels
	for child in chunk_container.get_children():
		child.queue_free()

	chunk_visuals.clear()
	create_chunk_visuals()

func spawn_chunk_content(chunk_pos: Vector2i):
	# Spawner des éléments dans le nouveau chunk
	var world_pos = chunk_to_world(chunk_pos)

	# Ajouter quelques ressources naturelles (arbres, rochers)
	var num_resources = randi() % 3 + 1
	for i in range(num_resources):
		var offset = Vector2(
			randf_range(-CHUNK_SIZE / 3, CHUNK_SIZE / 3),
			randf_range(-CHUNK_SIZE / 3, CHUNK_SIZE / 3)
		)
		# Ici on pourrait spawner des ressources permanentes
		# Pour l'instant on laisse le ResourceSpawner s'en occuper

func get_available_building_slots(chunk_pos: Vector2i) -> Array[Vector2]:
	# Retourne les positions disponibles pour construire dans un chunk
	if not is_chunk_unlocked(chunk_pos):
		return []

	var world_pos = chunk_to_world(chunk_pos)
	var slots: Array[Vector2] = []

	# 4 emplacements par chunk (aux coins)
	var offset = CHUNK_SIZE / 4
	slots.append(world_pos + Vector2(-offset, -offset))
	slots.append(world_pos + Vector2(offset, -offset))
	slots.append(world_pos + Vector2(-offset, offset))
	slots.append(world_pos + Vector2(offset, offset))

	return slots
