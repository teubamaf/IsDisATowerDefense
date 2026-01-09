extends Node2D
class_name Tower

# Types de tours
enum TowerType { CLASSIC, FIRE, ICE, POISON }

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

# Type de tour et spécialisation
var tower_type: TowerType = TowerType.CLASSIC
var is_specialized: bool = false
const SPECIALIZATION_LEVEL: int = 5

# Scènes d'explosion
var explosion_scene: PackedScene = preload("res://Scenes/VFX/Explosion.tscn")

# Scènes de projectiles
var projectile_scene: PackedScene = preload("res://Scenes/Projectiles/Arrow.tscn")
var fire_projectile_scene: PackedScene = preload("res://Scenes/Projectiles/Fire_projectile.tscn")
var ice_projectile_scene: PackedScene = preload("res://Scenes/Projectiles/Ice_projectile.tscn")
var poison_projectile_scene: PackedScene = preload("res://Scenes/Projectiles/Poison_projectile.tscn")

# Textures des tours
var tower_textures: Dictionary = {}

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
	# Créer un projectile et le tirer vers l'ennemi
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	projectile.global_position = global_position
	projectile.setup(enemy, damage)

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

		# Couleur selon le type de tour
		var base_color = get_tower_color()

		# Ajouter un effet visuel de sélection
		if is_selected:
			sprite.modulate = Color(base_color.r * 1.3, base_color.g * 1.3, base_color.b * 1.3)
		else:
			sprite.modulate = base_color

func get_tower_color() -> Color:
	match tower_type:
		TowerType.FIRE:
			return Color(1.0, 0.5, 0.3)  # Orange
		TowerType.ICE:
			return Color(0.5, 0.8, 1.0)  # Bleu clair
		TowerType.POISON:
			return Color(0.5, 1.0, 0.5)  # Vert
		_:
			return Color(0.4, 0.4, 0.8)  # Bleu foncé (classique)

func get_info_text() -> String:
	var type_name = get_tower_type_name()
	return "%s (Niv. %d)\nDégâts: %.1f\nPortée: %.0f\nVitesse: %.1f/s" % [type_name, level, damage, attack_range, attack_speed]

func get_tower_type_name() -> String:
	match tower_type:
		TowerType.FIRE:
			return "Tour de Feu"
		TowerType.ICE:
			return "Tour de Glace"
		TowerType.POISON:
			return "Tour Poison"
		_:
			return "Tour"

func can_specialize() -> bool:
	return level >= SPECIALIZATION_LEVEL and not is_specialized

func specialize(new_type: TowerType):
	if not can_specialize():
		return

	tower_type = new_type
	is_specialized = true

	# Changer le projectile selon le type
	match tower_type:
		TowerType.FIRE:
			projectile_scene = fire_projectile_scene
			damage *= 0.8  # Moins de dégâts directs mais AoE
		TowerType.ICE:
			projectile_scene = ice_projectile_scene
			attack_speed *= 0.8  # Attaque plus lente mais ralentit
		TowerType.POISON:
			projectile_scene = poison_projectile_scene
			damage *= 0.6  # Moins de dégâts directs mais DoT

	# Mettre à jour le timer d'attaque
	if attack_timer:
		attack_timer.wait_time = 1.0 / attack_speed

	# Changer le visuel
	update_tower_sprite()
	update_visual()

func update_tower_sprite():
	if not sprite:
		return

	# Charger la texture correspondant au type de tour
	var texture_path = ""
	match tower_type:
		TowerType.FIRE:
			texture_path = "res://Assets/Humans/Towers/Tower_fire.png"
		TowerType.ICE:
			texture_path = "res://Assets/Humans/Towers/Tower_ice.png"
		TowerType.POISON:
			texture_path = "res://Assets/Humans/Towers/Tower_poison.png"
		_:
			texture_path = "res://Assets/Humans/Towers/Tower_classic.png"

	if ResourceLoader.exists(texture_path):
		sprite.texture = load(texture_path)

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
		var base_color = get_tower_color()
		var normal_color = base_color if not is_selected else Color(base_color.r * 1.3, base_color.g * 1.3, base_color.b * 1.3)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.RED, 0.1)
		tween.tween_property(sprite, "modulate", normal_color, 0.1)

	if current_hp <= 0:
		die()

func die():
	building_destroyed.emit(self)

	# Spawner l'explosion
	var explosion = explosion_scene.instantiate()
	explosion.global_position = global_position
	get_tree().current_scene.add_child(explosion)

	queue_free()
