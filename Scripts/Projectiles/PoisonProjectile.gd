extends Projectile
class_name PoisonProjectile

# Projectile empoisonné - dégâts sur la durée

@export var poison_damage: float = 5.0
@export var poison_duration: float = 4.0

func _ready():
	super._ready()

func hit_enemy(enemy: Node2D):
	# Dégâts directs (plus faibles)
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)

	# Appliquer le poison
	apply_poison(enemy)

	# Effet visuel de poison
	spawn_poison_effect(enemy)

func apply_poison(enemy: Node2D):
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("poison", poison_damage, poison_duration)

func spawn_poison_effect(enemy: Node2D):
	if not is_instance_valid(enemy):
		return

	# Effet visuel - teinte verte sur l'ennemi
	var sprite = enemy.get_node_or_null("Sprite2D")
	if sprite:
		var original_color = sprite.modulate
		var tween = enemy.create_tween()
		tween.tween_property(sprite, "modulate", Color(0.5, 1.0, 0.5), 0.1)
		tween.tween_interval(poison_duration)
		tween.tween_property(sprite, "modulate", original_color, 0.2)
