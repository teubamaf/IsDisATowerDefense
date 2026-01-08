extends Node2D
class_name Building
# Types de bâtiments
enum BuildingType { MINE, SAWMILL, MARKET, TOWER, HERO_HALL }

@export var building_type: BuildingType = BuildingType.MINE
@export var level: int = 1
@export var max_level: int = 10

# Stats de vie
@export var max_hp: float = 100.0
var current_hp: float = 100.0

# Paramètres de spawn de ressources
@export var spawn_radius_base: float = 100.0
@export var spawn_interval_base: float = 8.0  # Secondes entre chaque spawn
@export var max_resources: int = 10  # Maximum de ressources actives autour du bâtiment

# Coûts d'amélioration
@export var upgrade_gold_cost: float = 50.0
@export var upgrade_wood_cost: float = 30.0

var spawn_timer: float = 0.0
var is_selected: bool = false
var spawned_resources: Array[Node] = []

# Signal de destruction
signal building_destroyed(building: Node2D)

# Scène de ressource récoltable
var harvestable_scene: PackedScene = preload("res://Scenes/Entities/HarvestableResource.tscn")

# Signal émis quand le bâtiment est cliqué
signal building_clicked(building: Node2D)

@onready var sprite = $Sprite2D
@onready var label = $LevelLabel
@onready var click_area: Area2D = null

func _ready():
	# Ajouter au groupe buildings pour la détection par les ennemis
	add_to_group("buildings")

	# Initialiser les HP
	current_hp = max_hp

	# Créer une zone cliquable
	create_click_area()
	update_visual()

func create_click_area():
	click_area = Area2D.new()
	click_area.name = "ClickArea"

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 40.0  # Rayon de la zone cliquable
	collision.shape = shape

	click_area.add_child(collision)
	click_area.input_event.connect(_on_click_area_input_event)
	add_child(click_area)

func _on_click_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# Émettre le signal de clic
		building_clicked.emit(self)
		# Informer le gestionnaire de sélection
		get_tree().call_group("building_manager", "select_building", self)

func _process(delta: float):
	# Ne pas spawner pour les Markets, Tours et HeroHall
	if building_type == BuildingType.MARKET or building_type == BuildingType.TOWER or building_type == BuildingType.HERO_HALL:
		return

	# Nettoyer les ressources détruites
	clean_spawned_resources()

	# Timer de spawn
	spawn_timer += delta
	var spawn_interval = get_spawn_interval()

	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		try_spawn_resource()

func get_spawn_radius() -> float:
	# La zone de spawn augmente de 15% par niveau
	return spawn_radius_base * (1.0 + level * 0.15)

func get_spawn_interval() -> float:
	# Le spawn devient 10% plus fréquent par niveau
	return spawn_interval_base / (1.0 + level * 0.1)

func clean_spawned_resources():
	spawned_resources = spawned_resources.filter(func(r): return is_instance_valid(r))

func try_spawn_resource():
	# Vérifier si on peut spawner
	if spawned_resources.size() >= max_resources:
		return

	spawn_resource()

func spawn_resource():
	var resource = harvestable_scene.instantiate()

	# Position aléatoire dans le rayon
	var spawn_radius = get_spawn_radius()
	var angle = randf() * TAU
	var distance = randf_range(spawn_radius * 0.3, spawn_radius)
	var spawn_pos = global_position + Vector2(cos(angle), sin(angle)) * distance

	resource.global_position = spawn_pos

	# Configurer le type de ressource selon le bâtiment
	configure_resource(resource)

	# Ajouter à la scène
	get_tree().current_scene.add_child(resource)
	spawned_resources.append(resource)

func configure_resource(resource: Node):
	# Accéder au script HarvestableResource
	match building_type:
		BuildingType.MINE:
			# Mine: 80% pierre, 15% or, 5% rare
			var roll = randf()
			if roll < 0.80:
				resource.resource_type = 1  # STONE
				resource.resource_amount = randf_range(5, 15) * (1 + level * 0.1)
			elif roll < 0.95:
				resource.resource_type = 2  # GOLD
				resource.resource_amount = randf_range(3, 10) * (1 + level * 0.1)
			else:
				resource.resource_type = 3  # RARE
				resource.resource_amount = randf_range(5, 20) * (1 + level * 0.1)

		BuildingType.SAWMILL:
			# Scierie: 100% bois
			resource.resource_type = 0  # WOOD
			resource.resource_amount = randf_range(5, 15) * (1 + level * 0.1)

func upgrade() -> bool:
	if level >= max_level:
		print("Niveau maximum atteint !")
		return false

	var cost_multiplier = level
	var gold_cost = upgrade_gold_cost * cost_multiplier
	var wood_cost = upgrade_wood_cost * cost_multiplier

	if GameManager.spend_resources(gold_cost, wood_cost, 0):
		level += 1
		update_visual()
		print("Bâtiment amélioré au niveau ", level)
		return true
	else:
		print("Ressources insuffisantes pour améliorer")
		return false

func set_selected(selected: bool):
	is_selected = selected
	update_visual()

func update_visual():
	if label:
		label.text = "Niv. %d" % level

	if sprite:
		# Augmenter légèrement la taille avec le niveau
		var scale_factor = 1.0 + (level * 0.05)
		sprite.scale = Vector2(scale_factor, scale_factor)

		# Ajouter un effet visuel de sélection
		if is_selected:
			sprite.modulate = Color(1.2, 1.2, 1.0)  # Légèrement plus lumineux/jaune
		else:
			sprite.modulate = Color(1.0, 1.0, 1.0)  # Normal

func get_info_text() -> String:
	var type_name = ""
	var production_info = ""

	match building_type:
		BuildingType.MINE:
			type_name = "Mine"
			production_info = "Spawn: Pierre (80%), Or (15%), Rare (5%)\nZone: %.0f px | Intervalle: %.1fs" % [get_spawn_radius(), get_spawn_interval()]
		BuildingType.SAWMILL:
			type_name = "Scierie"
			production_info = "Spawn: Bois (100%%)\nZone: %.0f px | Intervalle: %.1fs" % [get_spawn_radius(), get_spawn_interval()]
		BuildingType.MARKET:
			type_name = "Marché"
			production_info = "Achetez et vendez des ressources"
		BuildingType.TOWER:
			type_name = "Tour"
			production_info = "Bâtiment défensif"
		BuildingType.HERO_HALL:
			type_name = "Caserne de Héros"
			production_info = "Recrutez des héros pour défendre votre royaume"

	return "%s (Niv. %d)\n%s" % [type_name, level, production_info]

func get_upgrade_cost() -> Dictionary:
	if level >= max_level:
		return {"gold": 0, "wood": 0, "can_upgrade": false}

	var cost_multiplier = level
	return {
		"gold": upgrade_gold_cost * cost_multiplier,
		"wood": upgrade_wood_cost * cost_multiplier,
		"can_upgrade": true
	}

func take_damage(amount: float):
	current_hp -= amount

	# Effet visuel de dégâts
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.RED, 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE if not is_selected else Color(1.2, 1.2, 1.0), 0.1)

	if current_hp <= 0:
		die()

func die():
	building_destroyed.emit(self)
	queue_free()
