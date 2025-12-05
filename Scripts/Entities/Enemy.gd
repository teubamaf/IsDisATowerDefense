extends CharacterBody2D

# Statistiques de l'ennemi
@export var max_hp: float = 50.0
@export var speed: float = 50.0
@export var damage: float = 10.0
@export var gold_reward: float = 5.0
@export var attack_cooldown: float = 1.0

var current_hp: float
var castle_target: Node2D = null
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

	# Se déplacer vers le château
	var direction = (castle_target.global_position - global_position).normalized()
	velocity = direction * speed

	# Vérifier si on est assez proche pour attaquer
	var distance = global_position.distance_to(castle_target.global_position)
	if distance < 50.0:  # Distance d'attaque
		velocity = Vector2.ZERO
		if can_attack and castle_target.has_method("take_damage"):
			attack_castle()

	move_and_slide()

func attack_castle():
	if castle_target and castle_target.has_method("take_damage"):
		castle_target.take_damage(damage)
		print("Ennemi attaque le château ! Dégâts: ", damage)
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
