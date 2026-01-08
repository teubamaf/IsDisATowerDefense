extends Hero
class_name Paladin

# Sorts du Paladin
enum Spell { HOLY_STRIKE, DIVINE_SHIELD, HEALING_LIGHT }

# Cooldowns des sorts
var spell_cooldowns = {
	Spell.HOLY_STRIKE: 5.0,
	Spell.DIVINE_SHIELD: 15.0,
	Spell.HEALING_LIGHT: 10.0
}

var spell_ready = {
	Spell.HOLY_STRIKE: true,
	Spell.DIVINE_SHIELD: true,
	Spell.HEALING_LIGHT: true
}

# Stats spécifiques au Paladin
@export var holy_strike_damage: float = 50.0
@export var divine_shield_duration: float = 3.0
@export var healing_amount: float = 50.0

var is_shielded: bool = false

func _ready():
	super._ready()

	# Stats du Paladin (plus tanky)
	max_hp = 300.0
	current_hp = max_hp
	damage = 30.0
	speed = 80.0
	attack_range = 60.0
	attack_cooldown = 1.2

	update_hp_bar()

func _input(event: InputEvent):
	super._input(event)

	if is_selected:
		# Raccourcis pour les sorts
		if event.is_action_pressed("spell_1"):  # Touche 1
			cast_spell(Spell.HOLY_STRIKE)
		elif event.is_action_pressed("spell_2"):  # Touche 2
			cast_spell(Spell.DIVINE_SHIELD)
		elif event.is_action_pressed("spell_3"):  # Touche 3
			cast_spell(Spell.HEALING_LIGHT)

func cast_spell(spell_id: int):
	if not spell_ready[spell_id]:
		print("Sort en cooldown !")
		return

	match spell_id:
		Spell.HOLY_STRIKE:
			cast_holy_strike()
		Spell.DIVINE_SHIELD:
			cast_divine_shield()
		Spell.HEALING_LIGHT:
			cast_healing_light()

	# Démarrer le cooldown
	spell_ready[spell_id] = false
	start_spell_cooldown(spell_id)

func cast_holy_strike():
	print("Frappe Sacrée !")

	# Trouver tous les ennemis dans une zone
	var enemies = get_tree().get_nodes_in_group("enemies")
	var hit_count = 0

	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance <= attack_range * 1.5:  # Zone légèrement plus grande
				if enemy.has_method("take_damage"):
					enemy.take_damage(holy_strike_damage)
					hit_count += 1

	# Effet visuel
	show_spell_effect(Color.GOLD, attack_range * 1.5)

	if hit_count > 0:
		print("Frappe Sacrée a touché %d ennemis !" % hit_count)

func cast_divine_shield():
	print("Bouclier Divin activé !")
	is_shielded = true

	# Effet visuel - lueur bleue
	if sprite:
		sprite.modulate = Color(0.5, 0.5, 1.5)

	# Désactiver après la durée
	await get_tree().create_timer(divine_shield_duration).timeout
	if is_instance_valid(self):
		is_shielded = false
		update_visual()
		print("Bouclier Divin terminé")

func cast_healing_light():
	print("Lumière Guérisseuse !")
	current_hp = min(current_hp + healing_amount, max_hp)
	update_hp_bar()

	# Effet visuel - flash vert
	if sprite:
		var original = sprite.modulate
		sprite.modulate = Color.GREEN
		await get_tree().create_timer(0.3).timeout
		if is_instance_valid(self) and sprite:
			sprite.modulate = original if not is_selected else Color(1.3, 1.3, 1.0)

	print("HP restaurés: %.0f/%.0f" % [current_hp, max_hp])

func start_spell_cooldown(spell_id: int):
	await get_tree().create_timer(spell_cooldowns[spell_id]).timeout
	if is_instance_valid(self):
		spell_ready[spell_id] = true
		print("Sort %d prêt !" % spell_id)

func show_spell_effect(color: Color, radius: float):
	# Créer un cercle d'effet visuel
	var effect = Polygon2D.new()
	effect.color = Color(color.r, color.g, color.b, 0.3)

	# Créer un cercle
	var points = PackedVector2Array()
	for i in range(32):
		var angle = i * TAU / 32
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	effect.polygon = points

	add_child(effect)

	# Fade out
	var tween = create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.5)
	tween.finished.connect(effect.queue_free)

func take_damage(amount: float):
	if is_shielded:
		print("Dégâts bloqués par le Bouclier Divin !")
		# Petit effet visuel
		if sprite:
			var original = sprite.modulate
			sprite.modulate = Color.CYAN
			await get_tree().create_timer(0.1).timeout
			if is_instance_valid(self) and sprite:
				sprite.modulate = Color(0.5, 0.5, 1.5) if is_shielded else original
		return

	super.take_damage(amount)

func get_info_text() -> String:
	var base = "Paladin\nHP: %.0f/%.0f\nDégâts: %.0f" % [current_hp, max_hp, damage]
	base += "\n\nSorts:"
	base += "\n[1] Frappe Sacrée %s" % ("(Prêt)" if spell_ready[Spell.HOLY_STRIKE] else "(CD)")
	base += "\n[2] Bouclier Divin %s" % ("(Prêt)" if spell_ready[Spell.DIVINE_SHIELD] else "(CD)")
	base += "\n[3] Lumière Guérisseuse %s" % ("(Prêt)" if spell_ready[Spell.HEALING_LIGHT] else "(CD)")
	return base
