extends Node2D

# Types de bâtiments
enum BuildingType { MINE, SAWMILL, MARKET, TOWER }

@export var building_type: BuildingType = BuildingType.MINE
@export var production_rate: float = 1.0  # Ressources par seconde
@export var level: int = 1
@export var max_level: int = 10

# Coûts d'amélioration
@export var upgrade_gold_cost: float = 50.0
@export var upgrade_wood_cost: float = 30.0

var production_timer: float = 0.0

@onready var sprite = $Sprite2D
@onready var label = $LevelLabel

func _ready():
	update_visual()

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

func update_visual():
	if label:
		label.text = "Niv. %d" % level

	if sprite:
		# Augmenter légèrement la taille avec le niveau
		var scale_factor = 1.0 + (level * 0.05)
		sprite.scale = Vector2(scale_factor, scale_factor)

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
