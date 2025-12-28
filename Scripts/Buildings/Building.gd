extends Node2D
class_name Building
# Types de bâtiments
enum BuildingType { MINE, SAWMILL, MARKET, TOWER, HERO_HALL }

@export var building_type: BuildingType = BuildingType.MINE
@export var production_rate: float = 1.0  # Ressources par seconde
@export var level: int = 1
@export var max_level: int = 10

# Coûts d'amélioration
@export var upgrade_gold_cost: float = 50.0
@export var upgrade_wood_cost: float = 30.0

var production_timer: float = 0.0
var is_selected: bool = false

# Signal émis quand le bâtiment est cliqué
signal building_clicked(building: Node2D)

@onready var sprite = $Sprite2D
@onready var label = $LevelLabel
@onready var click_area: Area2D = null

func _ready():
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
	production_timer += delta

	# Produire des ressources chaque seconde
	if production_timer >= 1.0:
		production_timer = 0.0
		produce()

func produce():
	var amount = production_rate * level

	match building_type:
		BuildingType.MINE:
			GameManager.add_gold(amount)
			show_production_text("+%.1f Or" % amount, Color.GOLD)
		BuildingType.SAWMILL:
			GameManager.add_wood(amount)
			show_production_text("+%.1f Bois" % amount, Color.SADDLE_BROWN)
		BuildingType.MARKET:
			# Le marché génère de l'or
			GameManager.add_gold(amount * 1.5)
			show_production_text("+%.1f Or" % (amount * 1.5), Color.GOLD)

func show_production_text(text: String, color: Color):
	# Créer un label flottant pour montrer la production
	var floating_label = Label.new()
	floating_label.text = text
	floating_label.add_theme_color_override("font_color", color)
	floating_label.position = Vector2(0, -20)
	add_child(floating_label)

	# Animation
	var tween = create_tween()
	tween.tween_property(floating_label, "position:y", -50, 1.0)
	tween.parallel().tween_property(floating_label, "modulate:a", 0.0, 1.0)
	tween.finished.connect(floating_label.queue_free)

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
	match building_type:
		BuildingType.MINE:
			type_name = "Mine"
		BuildingType.SAWMILL:
			type_name = "Scierie"
		BuildingType.MARKET:
			type_name = "Marché"
		BuildingType.TOWER:
			type_name = "Tour"

	return "%s (Niv. %d)\nProduction: %.1f/s" % [type_name, level, production_rate * level]

func get_upgrade_cost() -> Dictionary:
	if level >= max_level:
		return {"gold": 0, "wood": 0, "can_upgrade": false}

	var cost_multiplier = level
	return {
		"gold": upgrade_gold_cost * cost_multiplier,
		"wood": upgrade_wood_cost * cost_multiplier,
		"can_upgrade": true
	}
