extends Projectile
class_name FireProjectile

# Projectile de feu - dégâts de zone + brûlure

@export var explosion_radius: float = 60.0
@export var burn_damage: float = 3.0
@export var burn_duration: float = 3.0

func _ready():
	super._ready()

func hit_enemy(enemy: Node2D):
	# Dégâts directs à la cible
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)

	# Appliquer brûlure à la cible
	apply_burn(enemy)

	# Dégâts de zone aux ennemis proches
	var enemies = get_tree().get_nodes_in_group("enemies")
	for other_enemy in enemies:
		if other_enemy != enemy and is_instance_valid(other_enemy):
			var distance = global_position.distance_to(other_enemy.global_position)
			if distance <= explosion_radius:
				# Dégâts réduits pour les ennemis dans la zone
				if other_enemy.has_method("take_damage"):
					other_enemy.take_damage(damage * 0.5)
				apply_burn(other_enemy)

	# Effet visuel d'explosion
	spawn_explosion_effect()

func apply_burn(enemy: Node2D):
	if enemy.has_method("apply_status_effect"):
		enemy.apply_status_effect("burn", burn_damage, burn_duration)

func spawn_explosion_effect():
	# Effet visuel simple - flash orange
	var effect = Sprite2D.new()
	effect.modulate = Color(1.0, 0.5, 0.0, 0.8)
	effect.scale = Vector2(explosion_radius / 16.0, explosion_radius / 16.0)
	get_tree().current_scene.add_child(effect)
	effect.global_position = global_position

	# Animation de disparition
	var tween = effect.create_tween()
	tween.tween_property(effect, "scale", Vector2.ZERO, 0.3)
	tween.tween_property(effect, "modulate:a", 0.0, 0.2)
	tween.tween_callback(effect.queue_free)
