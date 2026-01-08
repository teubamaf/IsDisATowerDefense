extends CharacterBody2D

# Statistiques de l'ennemi
@export var max_hp: float = 50.0
@export var speed: float = 50.0
@export var damage: float = 10.0
@export var gold_reward: float = 5.0
@export var attack_cooldown: float = 1.0
@export var detection_range: float = 150.0  # Portée de détection des bâtiments

var current_hp: float
var castle_target: Node2D = null
var current_target: Node2D = null  # Cible actuelle (bâtiment ou château)
var can_attack: bool = true

# Références
@onready var sprite = $Sprite2D
@onready var hp_bar = $HPBar
@onready var attack_timer = $AttackTimer

func _ready():
	current_hp = max_hp
	add_to_group("enemies")

	# Trouver le château
	await get_tree().process_frame
	castle_target = get_tree().get_first_node_in_group("castle")

	# Configuration du timer d'attaque
	if attack_timer:
		attack_timer.wait_time = attack_cooldown
		attack_timer.timeout.connect(_on_attack_timer_timeout)

	update_hp_bar()

func _physics_process(_delta: float):
	if castle_target == null or not is_instance_valid(castle_target):
		return

	# Chercher le bâtiment le plus proche dans la portée de détection
	find_nearest_target()

	# Déterminer la cible (bâtiment proche ou château)
	var target = current_target if current_target and is_instance_valid(current_target) else castle_target

	# Se déplacer vers la cible
	var direction = (target.global_position - global_position).normalized()
	velocity = direction * speed

	# Vérifier si on est assez proche pour attaquer
	var distance = global_position.distance_to(target.global_position)
	if distance < 50.0:  # Distance d'attaque
		velocity = Vector2.ZERO
		if can_attack:
			attack_target(target)

	move_and_slide()

func find_nearest_target():
	# Chercher le bâtiment le plus proche, en priorisant les tours (menaces)
	var buildings = get_tree().get_nodes_in_group("buildings")
	var closest_tower: Node2D = null
	var closest_tower_distance: float = detection_range
	var closest_building: Node2D = null
	var closest_building_distance: float = detection_range

	for building in buildings:
		if is_instance_valid(building) and building.has_method("take_damage"):
			var distance = global_position.distance_to(building.global_position)

			# Vérifier si c'est une tour (priorité)
			if building.get("is_tower") == true:
				if distance < closest_tower_distance:
					closest_tower_distance = distance
					closest_tower = building
			else:
				if distance < closest_building_distance:
					closest_building_distance = distance
					closest_building = building

	# Prioriser les tours, sinon cibler le bâtiment le plus proche
	if closest_tower:
		current_target = closest_tower
	else:
		current_target = closest_building

func attack_target(target: Node2D):
	if target and target.has_method("take_damage"):
		target.take_damage(damage)
		if target == castle_target:
			print("Ennemi attaque le château ! Dégâts: ", damage)
		else:
			print("Ennemi attaque un bâtiment ! Dégâts: ", damage)
		can_attack = false
		if attack_timer:
			attack_timer.start()

func _on_attack_timer_timeout():
	can_attack = true

func take_damage(amount: float):
	current_hp -= amount
	print("Ennemi prend ", amount, " dégâts. HP: ", current_hp, "/", max_hp)
	update_hp_bar()

	# Effet de dégât visuel
	flash_damage()

	if current_hp <= 0:
		die()

func flash_damage():
	if sprite:
		# Animation flash rouge
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.RED, 0.1)
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

func die():
	# Donner des récompenses
	GameManager.add_gold(gold_reward)
	print("Ennemi tué ! +", gold_reward, " or")

	# Effet de mort
	queue_free()

func update_hp_bar():
	if hp_bar and hp_bar is ProgressBar:
		hp_bar.max_value = max_hp
		hp_bar.value = current_hp
		hp_bar.visible = current_hp < max_hp
