extends CharacterBody2D
class_name Hero

# Stats de base du héros
@export var max_hp: float = 200.0
@export var current_hp: float = 200.0
@export var speed: float = 100.0
@export var damage: float = 25.0
@export var attack_range: float = 50.0
@export var detection_range: float = 200.0  # Portée de détection pour aller vers les ennemis
@export var attack_cooldown: float = 1.0

# État du héros
var is_selected: bool = false
var target_position: Vector2 = Vector2.ZERO
var is_moving: bool = false
var is_moving_to_enemy: bool = false  # Indique si on se déplace vers un ennemi
var current_target: Node2D = null
var can_attack: bool = true

# Références
@onready var sprite = $Sprite2D
@onready var attack_area: Area2D = null
@onready var hp_bar: ProgressBar = null

# Signaux
signal hero_died()
signal hero_selected(hero: Hero)
signal hero_deselected(hero: Hero)

func _ready():
	add_to_group("heroes")
	current_hp = max_hp
	target_position = global_position

	# Créer la zone d'attaque
	create_attack_area()

	# Créer la barre de vie
	create_hp_bar()

	# Créer la zone de clic pour sélection
	create_click_area()

	update_visual()

func create_attack_area():
	attack_area = Area2D.new()
	attack_area.name = "AttackArea"

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = attack_range
	collision.shape = shape

	attack_area.add_child(collision)
	attack_area.body_entered.connect(_on_enemy_entered)
	attack_area.body_exited.connect(_on_enemy_exited)

	# Configurer les collision layers (détecter les ennemis)
	attack_area.collision_layer = 0
	attack_area.collision_mask = 2  # Layer des ennemis

	add_child(attack_area)

func create_hp_bar():
	hp_bar = ProgressBar.new()
	hp_bar.name = "HPBar"
	hp_bar.max_value = max_hp
	hp_bar.value = current_hp
	hp_bar.show_percentage = false
	hp_bar.size = Vector2(40, 6)
	hp_bar.position = Vector2(-20, -30)

	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color.GREEN
	hp_bar.add_theme_stylebox_override("fill", style)

	add_child(hp_bar)

func create_click_area():
	var click_area = Area2D.new()
	click_area.name = "ClickArea"

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20.0
	collision.shape = shape

	click_area.add_child(collision)
	click_area.input_event.connect(_on_click_area_input)
	add_child(click_area)

func _on_click_area_input(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			# Si déjà sélectionné, désélectionner. Sinon, sélectionner.
			if is_selected:
				deselect()
			else:
				select()
			get_viewport().set_input_as_handled()

func _input(event: InputEvent):
	if is_selected:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT:
			# Déplacer vers la position du clic droit (ordre manuel)
			target_position = get_global_mouse_position()
			is_moving = true
			is_moving_to_enemy = false  # Annule le mouvement automatique vers ennemi
			current_target = null  # Reset la cible pour chercher une nouvelle
			get_viewport().set_input_as_handled()

		# Désélectionner avec Echap
		if event.is_action_pressed("ui_cancel"):
			deselect()

func _physics_process(delta: float):
	# Mouvement manuel vers la cible (ordre du joueur)
	if is_moving and not is_moving_to_enemy:
		var direction = (target_position - global_position).normalized()
		var distance = global_position.distance_to(target_position)

		if distance > 5:
			velocity = direction * speed
			move_and_slide()
			orient_sprite(direction)
		else:
			is_moving = false
			velocity = Vector2.ZERO

	# Chercher un ennemi à portée de détection
	if not is_moving or is_moving_to_enemy:
		find_target_in_detection_range()

	# Si on a une cible, se déplacer vers elle ou l'attaquer
	if current_target and is_instance_valid(current_target):
		var distance_to_target = global_position.distance_to(current_target.global_position)

		if distance_to_target <= attack_range:
			# À portée d'attaque - s'arrêter et attaquer
			is_moving_to_enemy = false
			velocity = Vector2.ZERO
			if can_attack:
				attack(current_target)
		else:
			# Hors portée d'attaque - se déplacer vers l'ennemi
			is_moving_to_enemy = true
			var direction = (current_target.global_position - global_position).normalized()
			velocity = direction * speed
			move_and_slide()
			orient_sprite(direction)
	else:
		# Pas de cible - arrêter le mouvement automatique
		if is_moving_to_enemy:
			is_moving_to_enemy = false
			velocity = Vector2.ZERO

func orient_sprite(direction: Vector2):
	if sprite:
		if direction.x < 0:
			sprite.flip_h = true
		elif direction.x > 0:
			sprite.flip_h = false

func find_target_in_detection_range():
	# Si on a déjà une cible valide, on la garde
	if current_target and is_instance_valid(current_target):
		return

	current_target = null
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_distance = detection_range

	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_distance = distance
				current_target = enemy

func find_target():
	current_target = null
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest_distance = attack_range

	for enemy in enemies:
		if is_instance_valid(enemy):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < closest_distance:
				closest_distance = distance
				current_target = enemy

func _on_enemy_entered(body: Node2D):
	if body.is_in_group("enemies") and current_target == null:
		current_target = body

func _on_enemy_exited(body: Node2D):
	if body == current_target:
		current_target = null
		find_target()

func attack(target: Node2D):
	if not can_attack:
		return

	can_attack = false

	# Infliger des dégâts
	if target.has_method("take_damage"):
		target.take_damage(damage)

	# Animation d'attaque (flash)
	if sprite:
		var original_modulate = sprite.modulate
		sprite.modulate = Color.RED
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(self) and sprite:
			sprite.modulate = original_modulate

	# Cooldown
	await get_tree().create_timer(attack_cooldown).timeout
	if is_instance_valid(self):
		can_attack = true

func take_damage(amount: float):
	current_hp -= amount
	update_hp_bar()

	# Flash de dégâts
	if sprite:
		var original_modulate = sprite.modulate
		sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(self) and sprite:
			sprite.modulate = original_modulate

	if current_hp <= 0:
		die()

func die():
	hero_died.emit()
	queue_free()

func select():
	# Désélectionner les autres héros
	for hero in get_tree().get_nodes_in_group("heroes"):
		if hero != self and hero.has_method("deselect"):
			hero.deselect()

	is_selected = true
	update_visual()
	hero_selected.emit(self)

func deselect():
	is_selected = false
	update_visual()
	hero_deselected.emit(self)

func update_visual():
	if sprite:
		if is_selected:
			sprite.modulate = Color(1.3, 1.3, 1.0)  # Plus lumineux quand sélectionné
		else:
			sprite.modulate = Color.WHITE

func update_hp_bar():
	if hp_bar:
		hp_bar.value = current_hp

		# Changer la couleur selon les HP
		var hp_ratio = current_hp / max_hp
		var style = hp_bar.get_theme_stylebox("fill") as StyleBoxFlat
		if style:
			if hp_ratio > 0.5:
				style.bg_color = Color.GREEN
			elif hp_ratio > 0.25:
				style.bg_color = Color.YELLOW
			else:
				style.bg_color = Color.RED

# Méthode virtuelle pour les sorts (à surcharger dans les sous-classes)
func cast_spell(spell_id: int):
	pass

func get_info_text() -> String:
	return "Héros\nHP: %.0f/%.0f\nDégâts: %.0f\nVitesse: %.0f" % [current_hp, max_hp, damage, speed]
