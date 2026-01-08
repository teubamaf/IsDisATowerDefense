extends Area2D
class_name Projectile

# Classe de base pour tous les projectiles

@export var speed: float = 400.0
@export var damage: float = 15.0

var target: Node2D = null
var direction: Vector2 = Vector2.ZERO

func _ready():
	body_entered.connect(_on_body_entered)

func _process(delta: float):
	if target != null and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
		rotation = direction.angle()

	global_position += direction * speed * delta

	if global_position.length() > 5000:
		queue_free()

func setup(target_enemy: Node2D, projectile_damage: float):
	target = target_enemy
	damage = projectile_damage
	if target != null and is_instance_valid(target):
		direction = (target.global_position - global_position).normalized()
		rotation = direction.angle()

func _on_body_entered(body: Node2D):
	if body.is_in_group("enemies"):
		hit_enemy(body)
		queue_free()

# Méthode à surcharger dans les classes enfants
func hit_enemy(enemy: Node2D):
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)

# Méthode pour appliquer des effets supplémentaires
func apply_effect(_enemy: Node2D):
	pass
