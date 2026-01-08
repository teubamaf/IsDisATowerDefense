extends Projectile
class_name IceProjectile

# Projectile de glace - ralentissement

@export var slow_percent: float = 0.5  # 50% de ralentissement
@export var slow_duration: float = 2.0

func _ready():
	super._ready()

func hit_enemy(enemy: Node2D):
	# Dégâts directs
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)

	# Appliquer le ralentissement
	apply_slow(enemy)

	# Effet visuel de gel
	spawn_frost_effect(enemy)

func apply_slow(enemy: Node2D):
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("slow", slow_percent, slow_duration)

func spawn_frost_effect(enemy: Node2D):
	if not is_instance_valid(enemy):
		return

	# Effet visuel - teinte bleue sur l'ennemi
	var sprite = enemy.get_node_or_null("Sprite2D")
	if sprite:
		var original_color = sprite.modulate
		var tween = enemy.create_tween()
		tween.tween_property(sprite, "modulate", Color(0.5, 0.8, 1.0), 0.1)
		tween.tween_interval(slow_duration)
		tween.tween_property(sprite, "modulate", original_color, 0.2)
