extends PanelContainer

# Panneau d'achat de héros depuis le Hero Hall

var current_hero_hall: Node2D = null

@onready var info_label = $VBoxContainer/InfoLabel
@onready var buy_button = $VBoxContainer/BuyButton
@onready var close_button = $VBoxContainer/CloseButton
@onready var upgrade_button = $VBoxContainer/UpgradeButton

func _ready():
	visible = false

	if buy_button:
		buy_button.pressed.connect(_on_buy_pressed)
	if close_button:
		close_button.pressed.connect(_on_close_pressed)
	if upgrade_button:
		upgrade_button.pressed.connect(_on_upgrade_pressed)

func show_panel(hero_hall: Node2D):
	current_hero_hall = hero_hall
	visible = true
	update_display()

func hide_panel():
	visible = false
	current_hero_hall = null

func update_display():
	if not current_hero_hall:
		return

	# Récupérer les infos du Hero Hall
	var has_hero = current_hero_hall.current_hero != null and is_instance_valid(current_hero_hall.current_hero)
	var level = current_hero_hall.level if current_hero_hall.get("level") else 1

	if info_label:
		var text = "Caserne de Héros (Niv. %d)\n\n" % level
		if has_hero:
			text += "Héros actif: Paladin\n"
			text += current_hero_hall.current_hero.get_info_text() if current_hero_hall.current_hero.has_method("get_info_text") else ""
		else:
			text += "Aucun héros actif\n\n"
			text += "Coût d'achat:\n"
			text += "%.0f Or, %.0f Bois, %.0f Pierre" % [
				current_hero_hall.hero_cost_gold,
				current_hero_hall.hero_cost_wood,
				current_hero_hall.hero_cost_stone
			]
		info_label.text = text

	if buy_button:
		if has_hero:
			buy_button.text = "Héros déjà actif"
			buy_button.disabled = true
		else:
			buy_button.text = "Acheter Paladin"
			buy_button.disabled = false

	if upgrade_button:
		var cost = current_hero_hall.get_upgrade_cost() if current_hero_hall.has_method("get_upgrade_cost") else {"can_upgrade": false}
		if cost["can_upgrade"]:
			upgrade_button.text = "Améliorer (%.0f Or, %.0f Bois)" % [cost["gold"], cost["wood"]]
			upgrade_button.disabled = false
		else:
			upgrade_button.text = "Niveau maximum"
			upgrade_button.disabled = true

func _on_buy_pressed():
	if current_hero_hall and current_hero_hall.has_method("purchase_hero"):
		if current_hero_hall.purchase_hero():
			update_display()

func _on_upgrade_pressed():
	if current_hero_hall and current_hero_hall.has_method("upgrade"):
		if current_hero_hall.upgrade():
			update_display()

func _on_close_pressed():
	hide_panel()
	get_tree().call_group("building_manager", "deselect_building")
