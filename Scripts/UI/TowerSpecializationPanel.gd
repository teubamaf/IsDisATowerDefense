extends PanelContainer

# Panneau de spécialisation des tours

var current_tower: Node2D = null

@onready var title_label = $VBoxContainer/Title
@onready var info_label = $VBoxContainer/InfoLabel
@onready var fire_btn = $VBoxContainer/FireButton
@onready var ice_btn = $VBoxContainer/IceButton
@onready var poison_btn = $VBoxContainer/PoisonButton
@onready var close_btn = $VBoxContainer/CloseButton

func _ready():
	visible = false

	if fire_btn:
		fire_btn.pressed.connect(_on_fire_pressed)
	if ice_btn:
		ice_btn.pressed.connect(_on_ice_pressed)
	if poison_btn:
		poison_btn.pressed.connect(_on_poison_pressed)
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)

func show_panel(tower: Node2D):
	current_tower = tower
	visible = true
	update_display()

func hide_panel():
	visible = false
	current_tower = null

func update_display():
	if not current_tower:
		return

	if info_label:
		info_label.text = "Choisissez une spécialisation pour votre tour niveau %d" % current_tower.level

func _on_fire_pressed():
	if current_tower and current_tower.has_method("specialize"):
		# TowerType.FIRE = 1
		current_tower.specialize(1)
		hide_panel()
		get_tree().call_group("building_manager", "deselect_building")

func _on_ice_pressed():
	if current_tower and current_tower.has_method("specialize"):
		# TowerType.ICE = 2
		current_tower.specialize(2)
		hide_panel()
		get_tree().call_group("building_manager", "deselect_building")

func _on_poison_pressed():
	if current_tower and current_tower.has_method("specialize"):
		# TowerType.POISON = 3
		current_tower.specialize(3)
		hide_panel()
		get_tree().call_group("building_manager", "deselect_building")

func _on_close_pressed():
	hide_panel()
	get_tree().call_group("building_manager", "deselect_building")
