extends Area2D

# Types de ressources récoltables
enum ResourceType { WOOD, STONE, GOLD, RARE }

@export var resource_type: ResourceType = ResourceType.STONE
@export var hits_required: int = 3
@export var resource_amount: float = 10.0
@export var lifetime: float = 30.0

var current_hits: int = 0

@onready var sprite = $Sprite2D
@onready var label = $Label
@onready var lifetime_timer = $LifetimeTimer
@onready var progress_label = $ProgressLabel

func _ready():
	# Configuration visuelle selon le type
	setup_visual()
	update_progress()

	# Connecter le signal de clic
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	# Timer de durée de vie
	if lifetime_timer:
		lifetime_timer.wait_time = lifetime
		lifetime_timer.timeout.connect(_on_lifetime_timeout)
		lifetime_timer.start()

	# Animation d'apparition
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func setup_visual():
	var color: Color
	var text: String

	match resource_type:
		ResourceType.WOOD:
			color = Color(0.4, 0.26, 0.13)  # Marron bois
			text = "+%d Bois" % int(resource_amount)
		ResourceType.STONE:
			color = Color(0.5, 0.5, 0.5)  # Gris pierre
			text = "+%d Pierre" % int(resource_amount)
		ResourceType.GOLD:
			color = Color.GOLD
			text = "+%d Or" % int(resource_amount)
		ResourceType.RARE:
			color = Color(0.6, 0.2, 0.8)  # Violet rare
			text = "+%d Rare" % int(resource_amount)

	if sprite:
		sprite.modulate = color

	if label:
		label.text = text

func update_progress():
	if progress_label:
		progress_label.text = "%d/%d" % [current_hits, hits_required]

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		hit()

func _on_mouse_entered():
	# Effet de survol
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.15, 1.15), 0.1)

func _on_mouse_exited():
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func hit():
	current_hits += 1
	update_progress()

	# Animation de hit (shake)
	var original_pos = position
	var tween = create_tween()
	tween.tween_property(self, "position", original_pos + Vector2(randf_range(-5, 5), randf_range(-5, 5)), 0.05)
	tween.tween_property(self, "position", original_pos, 0.05)

	# Flash de couleur
	if sprite:
		var original_modulate = sprite.modulate
		sprite.modulate = Color.WHITE
		await get_tree().create_timer(0.1).timeout
		if is_instance_valid(self) and sprite:
			sprite.modulate = original_modulate

	# Vérifier si cassé
	if current_hits >= hits_required:
		harvest()

func harvest():
	# Ajouter les ressources au GameManager
	match resource_type:
		ResourceType.WOOD:
			GameManager.add_wood(resource_amount)
		ResourceType.STONE:
			GameManager.add_stone(resource_amount)
		ResourceType.GOLD:
			GameManager.add_gold(resource_amount)
		ResourceType.RARE:
			# Pour l'instant, les ressources rares donnent de l'or bonus
			GameManager.add_gold(resource_amount * 2)

	# Animation de destruction
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.finished.connect(queue_free)

func _on_lifetime_timeout():
	# Disparition progressive si non récolté
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.finished.connect(queue_free)
