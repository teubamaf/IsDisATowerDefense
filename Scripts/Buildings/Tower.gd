extends Node2D

@export var damage: float = 15.0
@export var attack_speed: float = 1.0
@export var attack_range: float = 200.0
@export var level: int = 1
@export var max_level: int = 10

# Stats de vie (les tours ont plus de HP)
@export var max_hp: float = 200.0
var current_hp: float = 200.0

# Marqueur pour indiquer que c'est une tour (menace pour les ennemis)
var is_tower: bool = true

# Scène de la flèche à instancier
var arrow_scene: PackedScene = preload("res://Scenes/Projectiles/Arrow.tscn")

# Coûts d'amélioration
@export var upgrade_gold_cost: float = 100.0
@export var upgrade_wood_cost: float = 50.0
@export var upgrade_stone_cost: float = 20.0

var enemies_in_range: Array[Node2D] = []
var current_target: Node2D = null
var is_selected: bool = false

# Signal de destruction
signal building_destroyed(building: Node2D)

# Signal émis quand la tour est cliquée
signal building_clicked(building: Node2D)

@onready var attack_area = $AttackRange/CollisionShape2D
@onready var attack_timer = $AttackTimer
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

	# Configurer la portée
	if attack_area and attack_area is CollisionShape2D:
		var shape = CircleShape2D.new()
		shape.radius = attack_range
		attack_area.shape = shape

	# Configurer le timer
	if attack_timer:
		attack_timer.wait_time = 1.0 / attack_speed
		attack_timer.timeout.connect(_on_attack_timer_timeout)
		attack_timer.start()

	# Connecter les signaux
	$AttackRange.body_entered.connect(_on_body_entered)
	$AttackRange.body_exited.connect(_on_body_exited)

	update_visual()

func create_click_area():
	click_area = Area2D.new()
	click_area.name = "ClickArea"

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 40.0
	collision.shape = shape

	click_area.add_child(collision)
	click_area.input_event.connect(_on_click_area_input_event)
	add_child(click_area)

func _on_click_area_input_event(_viewport, event, _shape_idx):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		building_clicked.emit(self)
		get_tree().call_group("building_manager", "select_building", self)

func _process(_delta: float):
	if current_target == null or not is_instance_valid(current_target):
		find_target()

func find_target():
	current_target = null
	var closest_distance = attack_range

	for enemy in enemies_in_range:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_distance = distance
				current_target = enemy
		else:
			enemies_in_range.erase(enemy)

func _on_attack_timer_timeout():
	if current_target != null and is_instance_valid(current_target):
		attack(current_target)

func attack(enemy: Node2D):
	# Créer une flèche et la tirer vers l'ennemi
	var arrow = arrow_scene.instantiate()
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = global_position
	arrow.setup(enemy, damage)

func _on_body_entered(body: Node2D):
	if body.is_in_group("enemies"):
		enemies_in_range.append(body)

func _on_body_exited(body: Node2D):
	enemies_in_range.erase(body)
	if current_target == body:
		current_target = null

# Système d'amélioration
func upgrade() -> bool:
	if level >= max_level:
		print("Niveau maximum atteint !")
		return false

	var cost_multiplier = level
	var gold_cost = upgrade_gold_cost * cost_multiplier
	var wood_cost = upgrade_wood_cost * cost_multiplier
	var stone_cost = upgrade_stone_cost * cost_multiplier

	if GameManager.spend_resources(gold_cost, wood_cost, stone_cost):
		level += 1

		# Améliorer les stats de la tour
		damage *= 1.15  # +15% de dégâts par niveau
		attack_range *= 1.05  # +5% de portée par niveau

		# Mettre à jour la portée visuelle
		if attack_area and attack_area is CollisionShape2D:
			var shape = attack_area.shape as CircleShape2D
			if shape:
				shape.radius = attack_range

		update_visual()
		print("Tour améliorée au niveau ", level)
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
		# Augmenter légèrement la taille avec le niveau (base 0.5)
		var scale_factor = 0.5 * (1.0 + (level * 0.05))
		sprite.scale = Vector2(scale_factor, scale_factor)

		# Ajouter un effet visuel de sélection
		if is_selected:
			sprite.modulate = Color(1.2, 1.2, 1.0)
		else:
			sprite.modulate = Color(0.4, 0.4, 0.8)

func get_info_text() -> String:
	return "Tour (Niv. %d)\nDégâts: %.1f\nPortée: %.0f\nVitesse: %.1f/s" % [level, damage, attack_range, attack_speed]

func get_upgrade_cost() -> Dictionary:
	if level >= max_level:
		return {"gold": 0, "wood": 0, "stone": 0, "can_upgrade": false}

	var cost_multiplier = level
	return {
		"gold": upgrade_gold_cost * cost_multiplier,
		"wood": upgrade_wood_cost * cost_multiplier,
		"stone": upgrade_stone_cost * cost_multiplier,
		"can_upgrade": true
	}

func take_damage(amount: float):
	current_hp -= amount

	# Effet visuel de dégâts
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.RED, 0.1)
		tween.tween_property(sprite, "modulate", Color(0.4, 0.4, 0.8) if not is_selected else Color(1.2, 1.2, 1.0), 0.1)

	if current_hp <= 0:
		die()

func die():
	building_destroyed.emit(self)
	queue_free()
