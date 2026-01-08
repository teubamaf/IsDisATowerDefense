extends Node2D

@onready var game_manager = GameManager

# Références de nœuds
@onready var sprite = $Sprite2D
@onready var attack_area = $AttackRange/CollisionShape2D
@onready var attack_timer = $AttackTimer
@onready var hp_bar = $HPBar

# Race et skins
var race: String = "human"
var race_skins = {
	"human": preload("res://Assets/Humans/HumanCastle.png"),
	"orc": preload("res://Assets/Orcs/OrcCastle.png")
	#"elf": preload("res://Assets/Elves/ElfCastle.png"),
	#"dwarf": preload("res://Assets/Dwarves/DwarfCastle.png")
}

# Combat
var enemies_in_range: Array[Node2D] = []
var current_target: Node2D = null

func _ready():
	# Appliquer le skin de la race
	apply_race_skin()
	# Configurer la portée d'attaque
	if attack_area and attack_area is CollisionShape2D:
		var shape = CircleShape2D.new()
		shape.radius = game_manager.castle_attack_range
		attack_area.shape = shape

	# Configurer le timer d'attaque
	if attack_timer:
		attack_timer.wait_time = 1.0 / game_manager.castle_attack_speed
		attack_timer.timeout.connect(_on_attack_timer_timeout)
		attack_timer.start()

	# Connecter aux signaux du GameManager
	game_manager.castle_hp_changed.connect(_on_hp_changed)

	# Initialiser la barre de vie
	update_hp_bar()

func _process(_delta: float):
	# Trouver une cible
	if current_target == null or not is_instance_valid(current_target):
		find_target()

func find_target():
	current_target = null
	var closest_distance = game_manager.castle_attack_range

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
	if enemy.has_method("take_damage"):
		enemy.take_damage(game_manager.castle_damage)
		print("Château attaque ! Dégâts: ", game_manager.castle_damage)
		# Effet visuel ou son ici

func _on_attack_range_body_entered(body: Node2D):
	if body.is_in_group("enemies"):
		enemies_in_range.append(body)
		print("Ennemi détecté à portée ! Total: ", enemies_in_range.size())

func _on_attack_range_body_exited(body: Node2D):
	enemies_in_range.erase(body)
	if current_target == body:
		current_target = null

func take_damage(damage: float):
	game_manager.damage_castle(damage)

func _on_hp_changed(current_hp: float, max_hp: float):
	update_hp_bar()

func update_hp_bar():
	if hp_bar and hp_bar is ProgressBar:
		hp_bar.max_value = game_manager.castle_max_hp
		hp_bar.value = game_manager.castle_hp

func set_race(new_race: String):
	race = new_race
	if is_node_ready():
		apply_race_skin()

func apply_race_skin():
	if sprite and race_skins.has(race):
		sprite.texture = race_skins[race]
	else:
		push_warning("Skin non trouvé pour la race: " + race)
