extends Node2D

@export var damage: float = 15.0
@export var attack_speed: float = 1.0
@export var attack_range: float = 200.0

var enemies_in_range: Array[Node2D] = []
var current_target: Node2D = null

@onready var attack_area = $AttackRange/CollisionShape2D
@onready var attack_timer = $AttackTimer
@onready var sprite = $Sprite2D

func _ready():
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
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)

func _on_body_entered(body: Node2D):
	if body.is_in_group("enemies"):
		enemies_in_range.append(body)

func _on_body_exited(body: Node2D):
	enemies_in_range.erase(body)
	if current_target == body:
		current_target = null
