extends Projectile
class_name Arrow

# Flèche classique - dégâts directs simples

func _ready():
	super._ready()

func _process(delta: float):
	if target != null and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
		# +45° car le sprite de flèche est incliné
		rotation = direction.angle() + PI / 4

	global_position += direction * speed * delta

	if global_position.length() > 5000:
		queue_free()

func setup(target_enemy: Node2D, arrow_damage: float):
	target = target_enemy
	damage = arrow_damage
	if target != null and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
		rotation = direction.angle() + PI / 4
