extends Area2D

# Types de ressources
enum ResourceType { GOLD, WOOD, STONE }

@export var resource_type: ResourceType = ResourceType.GOLD
@export var min_amount: float = 1.0
@export var max_amount: float = 5.0
@export var lifetime: float = 10.0  # Durée de vie avant disparition

var amount: float
@onready var sprite = $Sprite2D
@onready var label = $Label
@onready var lifetime_timer = $LifetimeTimer

func _ready():
	# Générer un montant aléatoire
	amount = randf_range(min_amount, max_amount)

	# Configuration visuelle selon le type
	setup_visual()

	# Connecter le signal de clic
	input_event.connect(_on_input_event)
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	# Timer de durée de vie
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
		ResourceType.GOLD:
			color = Color.GOLD
			text = "+%d Or" % int(amount)
		ResourceType.WOOD:
			color = Color.SADDLE_BROWN
			text = "+%d Bois" % int(amount)
		ResourceType.STONE:
			color = Color.GRAY
			text = "+%d Pierre" % int(amount)

	if sprite:
		sprite.modulate = color

	if label:
		label.text = text

func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		collect()

func _on_mouse_entered():
	# Effet de survol
	scale = Vector2(1.1, 1.1)

func _on_mouse_exited():
	scale = Vector2.ONE

func collect():
	# Ajouter les ressources au GameManager
	match resource_type:
		ResourceType.GOLD:
			GameManager.add_gold(amount)
		ResourceType.WOOD:
			GameManager.add_wood(amount)
		ResourceType.STONE:
			GameManager.add_stone(amount)

	# Animation de collecte
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tween.tween_property(self, "global_position", global_position + Vector2(0, -30), 0.2)
	tween.finished.connect(queue_free)

func _on_lifetime_timeout():
	# Disparition progressive
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 1.0)
	tween.finished.connect(queue_free)
