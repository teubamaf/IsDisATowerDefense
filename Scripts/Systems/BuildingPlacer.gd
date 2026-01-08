extends Node2D

# Système de placement de bâtiments

enum BuildMode { NONE, MINE, SAWMILL, MARKET, TOWER, HERO_HALL }

var current_build_mode: BuildMode = BuildMode.NONE
var ghost_building: Node2D = null
var can_place: bool = false

# Grille de placement
const GRID_SIZE: int = 64
var occupied_cells: Array[Vector2i] = []

# Zone interdite autour du château
const CASTLE_NO_BUILD_RADIUS: float = 150.0

# Taille des bâtiments en cellules (pour les bâtiments multi-cases)
const BUILDING_SIZES = {
	BuildMode.MINE: Vector2i(1, 1),
	BuildMode.SAWMILL: Vector2i(1, 1),
	BuildMode.MARKET: Vector2i(1, 1),
	BuildMode.TOWER: Vector2i(1, 1),
	BuildMode.HERO_HALL: Vector2i(1, 1)
}

# Indicateur visuel de placement
var placement_indicator: Polygon2D = null

# Scènes de bâtiments
@export var mine_scene: PackedScene
@export var sawmill_scene: PackedScene
@export var market_scene: PackedScene
@export var tower_scene: PackedScene
@export var hero_hall_scene: PackedScene

# Coûts
const COSTS = {
	BuildMode.MINE: {"gold": 50, "wood": 20, "stone": 0},
	BuildMode.SAWMILL: {"gold": 40, "wood": 30, "stone": 0},
	BuildMode.MARKET: {"gold": 80, "wood": 40, "stone": 0},
	BuildMode.TOWER: {"gold": 100, "wood": 50, "stone": 20},
	BuildMode.HERO_HALL: {"gold": 200, "wood": 100, "stone": 50}
}

func _ready():
	pass

func _process(_delta: float):
	if current_build_mode != BuildMode.NONE and ghost_building:
		# Suivre la souris avec snap sur grille
		var mouse_pos = get_global_mouse_position()
		var snapped_pos = snap_to_grid(mouse_pos)
		ghost_building.global_position = snapped_pos

		# Vérifier si on peut placer (toutes les cellules requises)
		var building_size = BUILDING_SIZES[current_build_mode]
		can_place = can_place_building(snapped_pos, building_size)

		# Mettre à jour l'indicateur de placement
		update_placement_indicator(snapped_pos, building_size, can_place)

		# Changer la couleur du ghost
		if ghost_building.has_node("Sprite2D"):
			var sprite = ghost_building.get_node("Sprite2D")
			sprite.modulate = Color.GREEN if can_place else Color.RED
			sprite.modulate.a = 0.5

func _input(event: InputEvent):
	if current_build_mode != BuildMode.NONE:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			if can_place:
				place_building()
			# Consommer l'événement pour éviter que le bâtiment soit sélectionné
			get_viewport().set_input_as_handled()

		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_build_mode()
			get_viewport().set_input_as_handled()

func start_build_mode(mode: BuildMode):
	print("start_build_mode appelé avec mode: ", mode)

	if current_build_mode != BuildMode.NONE:
		cancel_build_mode()

	# Vérifier les ressources
	var cost = COSTS[mode]
	print("Coût: ", cost["gold"], " or, ", cost["wood"], " bois, ", cost["stone"], " pierre")
	print("Ressources actuelles: ", GameManager.gold, " or, ", GameManager.wood, " bois, ", GameManager.stone, " pierre")

	if not GameManager.can_afford(cost["gold"], cost["wood"], cost["stone"]):
		print("❌ Ressources insuffisantes !")
		return

	current_build_mode = mode

	# Créer l'indicateur de placement
	create_placement_indicator()

	# Créer le ghost
	var scene = get_scene_for_mode(mode)
	if scene:
		ghost_building = scene.instantiate()
		add_child(ghost_building)

		# Désactiver complètement le ghost
		disable_ghost_functionality(ghost_building)

		print("Mode construction: ", mode, " activé. Clic gauche pour placer, clic droit pour annuler.")

func cancel_build_mode():
	if ghost_building:
		ghost_building.queue_free()
		ghost_building = null

	# Supprimer l'indicateur de placement
	if placement_indicator:
		placement_indicator.queue_free()
		placement_indicator = null

	current_build_mode = BuildMode.NONE
	print("Construction annulée")

func place_building():
	print("Tentative de placement...")
	var cost = COSTS[current_build_mode]

	if GameManager.spend_resources(cost["gold"], cost["wood"], cost["stone"]):
		# Créer le vrai bâtiment
		var scene = get_scene_for_mode(current_build_mode)
		if scene:
			var building = scene.instantiate()
			building.global_position = ghost_building.global_position
			get_parent().get_node("Buildings").add_child(building)

			# Marquer toutes les cellules comme occupées
			var building_size = BUILDING_SIZES[current_build_mode]
			var base_grid_pos = world_to_grid(building.global_position)
			for x in range(building_size.x):
				for y in range(building_size.y):
					var cell = base_grid_pos + Vector2i(x, y)
					occupied_cells.append(cell)

			print("✅ Bâtiment placé à ", building.global_position)

			# Désélectionner tout bâtiment pour éviter que le panel s'affiche
			await get_tree().process_frame
			get_tree().call_group("building_manager", "deselect_building")
		else:
			print("❌ Erreur: scène de bâtiment introuvable")
	else:
		print("❌ Impossible de dépenser les ressources")

	cancel_build_mode()

func get_scene_for_mode(mode: BuildMode) -> PackedScene:
	match mode:
		BuildMode.MINE:
			return mine_scene
		BuildMode.SAWMILL:
			return sawmill_scene
		BuildMode.MARKET:
			return market_scene
		BuildMode.TOWER:
			return tower_scene
		BuildMode.HERO_HALL:
			return hero_hall_scene
	return null

func snap_to_grid(pos: Vector2) -> Vector2:
	return Vector2(
		round(pos.x / GRID_SIZE) * GRID_SIZE,
		round(pos.y / GRID_SIZE) * GRID_SIZE
	)

func world_to_grid(pos: Vector2) -> Vector2i:
	return Vector2i(
		int(round(pos.x / GRID_SIZE)),
		int(round(pos.y / GRID_SIZE))
	)

func is_cell_occupied(grid_pos: Vector2i) -> bool:
	return grid_pos in occupied_cells

func can_place_building(world_pos: Vector2, size: Vector2i) -> bool:
	# Vérifier si la position est dans une zone débloquée (pas de brouillard)
	var chunk_grid = get_parent().get_node_or_null("ChunkGrid")
	if chunk_grid and not chunk_grid.is_position_in_unlocked_chunk(world_pos):
		return false

	# Vérifier la distance au château (zone interdite)
	var castle = get_tree().get_first_node_in_group("castle")
	if castle:
		var distance_to_castle = world_pos.distance_to(castle.global_position)
		if distance_to_castle < CASTLE_NO_BUILD_RADIUS:
			return false

	var base_grid_pos = world_to_grid(world_pos)
	for x in range(size.x):
		for y in range(size.y):
			var cell = base_grid_pos + Vector2i(x, y)
			if is_cell_occupied(cell):
				return false
	return true

func disable_ghost_functionality(node: Node):
	# Désactiver récursivement tous les scripts et zones de collision
	if node.has_method("set_process"):
		node.set_process(false)
	if node.has_method("set_physics_process"):
		node.set_physics_process(false)

	# Désactiver les Area2D et leurs collisions
	if node is Area2D:
		node.monitoring = false
		node.monitorable = false
		# Désactiver la réception des événements d'entrée
		node.input_pickable = false

	# Désactiver les timers
	if node is Timer:
		node.stop()

	# Récursif sur les enfants
	for child in node.get_children():
		disable_ghost_functionality(child)

# Indicateur visuel de placement (zone sous le bâtiment)
func create_placement_indicator():
	placement_indicator = Polygon2D.new()
	placement_indicator.z_index = -1  # Sous le ghost
	add_child(placement_indicator)

func update_placement_indicator(world_pos: Vector2, size: Vector2i, is_valid: bool):
	if not placement_indicator:
		return

	placement_indicator.global_position = world_pos

	# Créer le polygone selon la taille du bâtiment
	var half_cell = GRID_SIZE / 2.0
	var width = size.x * GRID_SIZE
	var height = size.y * GRID_SIZE

	placement_indicator.polygon = PackedVector2Array([
		Vector2(-half_cell, -half_cell),
		Vector2(-half_cell + width, -half_cell),
		Vector2(-half_cell + width, -half_cell + height),
		Vector2(-half_cell, -half_cell + height)
	])

	# Couleur selon si le placement est valide
	if is_valid:
		placement_indicator.color = Color(0.2, 0.8, 0.2, 0.3)  # Vert transparent
	else:
		placement_indicator.color = Color(0.8, 0.2, 0.2, 0.3)  # Rouge transparent
