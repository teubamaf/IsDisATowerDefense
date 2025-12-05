extends Node2D

# Système de placement de bâtiments

enum BuildMode { NONE, MINE, SAWMILL, MARKET, TOWER }

var current_build_mode: BuildMode = BuildMode.NONE
var ghost_building: Node2D = null
var can_place: bool = false

# Grille de placement
const GRID_SIZE: int = 64
var occupied_cells: Array[Vector2i] = []

# Scènes de bâtiments
@export var mine_scene: PackedScene
@export var sawmill_scene: PackedScene
@export var market_scene: PackedScene
@export var tower_scene: PackedScene

# Coûts
const COSTS = {
	BuildMode.MINE: {"gold": 50, "wood": 20, "stone": 0},
	BuildMode.SAWMILL: {"gold": 40, "wood": 30, "stone": 0},
	BuildMode.MARKET: {"gold": 80, "wood": 40, "stone": 0},
	BuildMode.TOWER: {"gold": 100, "wood": 50, "stone": 20}
}

func _ready():
	pass

func _process(_delta: float):
	if current_build_mode != BuildMode.NONE and ghost_building:
		# Suivre la souris avec snap sur grille
		var mouse_pos = get_global_mouse_position()
		var snapped_pos = snap_to_grid(mouse_pos)
		ghost_building.global_position = snapped_pos

		# Vérifier si on peut placer
		var grid_pos = world_to_grid(snapped_pos)
		can_place = not is_cell_occupied(grid_pos)

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

		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			cancel_build_mode()

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

			# Marquer la cellule comme occupée
			var grid_pos = world_to_grid(building.global_position)
			occupied_cells.append(grid_pos)

			print("✅ Bâtiment placé à ", building.global_position)
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

	# Désactiver les timers
	if node is Timer:
		node.stop()

	# Récursif sur les enfants
	for child in node.get_children():
		disable_ghost_functionality(child)
