extends Area2D

@export var speed: float = 400.0
@export var damage: float = 15.0

var target: Node2D = null
var direction: Vector2 = Vector2.ZERO

func _ready():
	# Connecter le signal de collision
	body_entered.connect(_on_body_entered)

func _process(delta: float):
	if target != null and is_instance_valid(target):
		# Calculer la direction vers la cible
		direction = (target.global_position - global_position).normalized()
		# Orienter la flèche vers la cible
		rotation = direction.angle() + PI / 4  # +45° car le sprite est incliné

	# Déplacer la flèche
	global_position += direction * speed * delta

	# Détruire si hors écran ou trop loin
	if global_position.length() > 5000:
		queue_free()

func setup(target_enemy: Node2D, arrow_damage: float):
	target = target_enemy
	damage = arrow_damage
	if target != null and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
		rotation = direction.angle() + PI / 4

func _on_body_entered(body: Node2D):
	if body.is_in_group("enemies"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
