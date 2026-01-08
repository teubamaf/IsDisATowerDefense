extends Node

# Gestionnaire de sélection et d'amélioration de bâtiments

var selected_building: Node2D = null

# Référence à l'UI
@onready var upgrade_panel: Control = null
@onready var market_panel: Control = null
@onready var hero_hall_panel: Control = null
@onready var specialization_panel: Control = null

func _ready():
	# Trouver les panneaux dans l'UI
	await get_tree().process_frame
	upgrade_panel = get_node_or_null("/root/Game/GameUI/UpgradePanel")
	market_panel = get_node_or_null("/root/Game/GameUI/MarketPanel")
	hero_hall_panel = get_node_or_null("/root/Game/GameUI/HeroHallPanel")
	specialization_panel = get_node_or_null("/root/Game/GameUI/TowerSpecializationPanel")

	if upgrade_panel:
		upgrade_panel.visible = false
	if market_panel:
		market_panel.visible = false
	if hero_hall_panel:
		hero_hall_panel.visible = false
	if specialization_panel:
		specialization_panel.visible = false

func select_building(building: Node2D, show_panel: bool = true):
	# Désélectionner le bâtiment précédent
	if selected_building and selected_building != building:
		if selected_building.has_method("set_selected"):
			selected_building.set_selected(false)

	# Sélectionner le nouveau bâtiment
	selected_building = building

	if selected_building and selected_building.has_method("set_selected"):
		selected_building.set_selected(true)

	# Afficher le panneau approprié seulement si demandé
	if show_panel:
		show_appropriate_panel()
	else:
		hide_all_panels()

func deselect_building():
	if selected_building and selected_building.has_method("set_selected"):
		selected_building.set_selected(false)

	selected_building = null
	hide_all_panels()

func show_appropriate_panel():
	if not selected_building:
		return

	# Vérifier le type de bâtiment
	if selected_building.has_method("get_info_text"):
		var building_type = selected_building.get("building_type")
		# BuildingType: MINE=0, SAWMILL=1, MARKET=2, TOWER=3, HERO_HALL=4
		if building_type == 2:  # MARKET
			show_market_panel()
			return
		elif building_type == 4:  # HERO_HALL
			show_hero_hall_panel()
			return

	# Vérifier si c'est une tour qui peut être spécialisée
	if selected_building.has_method("can_specialize"):
		if selected_building.can_specialize():
			show_specialization_panel()
			return

	# Sinon afficher le panneau d'amélioration standard
	show_upgrade_panel()

func show_upgrade_panel():
	hide_market_panel()
	hide_hero_hall_panel()

	if not upgrade_panel or not selected_building:
		return

	upgrade_panel.visible = true

	# Mettre à jour les informations du panneau
	var info_label = upgrade_panel.get_node_or_null("VBoxContainer/InfoLabel")
	if not info_label:
		info_label = upgrade_panel.get_node_or_null("InfoLabel")
	if info_label:
		info_label.text = selected_building.get_info_text()

	var upgrade_button = upgrade_panel.get_node_or_null("VBoxContainer/UpgradeButton")
	if not upgrade_button:
		upgrade_button = upgrade_panel.get_node_or_null("UpgradeButton")
	if upgrade_button:
		var cost = selected_building.get_upgrade_cost()
		if cost["can_upgrade"]:
			# Afficher le coût selon le type de bâtiment
			if cost.has("stone") and cost["stone"] > 0:
				upgrade_button.text = "Améliorer (%.0f Or, %.0f Bois, %.0f Pierre)" % [cost["gold"], cost["wood"], cost["stone"]]
			else:
				upgrade_button.text = "Améliorer (%.0f Or, %.0f Bois)" % [cost["gold"], cost["wood"]]
			upgrade_button.disabled = false
		else:
			upgrade_button.text = "Niveau maximum"
			upgrade_button.disabled = true

func show_market_panel():
	hide_upgrade_panel()
	hide_hero_hall_panel()

	if not market_panel or not selected_building:
		return

	var level = selected_building.get("level")
	if level == null:
		level = 1

	if market_panel.has_method("show_panel"):
		market_panel.show_panel(level)
	else:
		market_panel.visible = true

func show_hero_hall_panel():
	hide_upgrade_panel()
	hide_market_panel()

	if not hero_hall_panel or not selected_building:
		return

	if hero_hall_panel.has_method("show_panel"):
		hero_hall_panel.show_panel(selected_building)
	else:
		hero_hall_panel.visible = true

func hide_upgrade_panel():
	if upgrade_panel:
		upgrade_panel.visible = false

func hide_market_panel():
	if market_panel:
		if market_panel.has_method("hide_panel"):
			market_panel.hide_panel()
		else:
			market_panel.visible = false

func hide_hero_hall_panel():
	if hero_hall_panel:
		if hero_hall_panel.has_method("hide_panel"):
			hero_hall_panel.hide_panel()
		else:
			hero_hall_panel.visible = false

func show_specialization_panel():
	hide_upgrade_panel()
	hide_market_panel()
	hide_hero_hall_panel()

	if not specialization_panel or not selected_building:
		return

	if specialization_panel.has_method("show_panel"):
		specialization_panel.show_panel(selected_building)
	else:
		specialization_panel.visible = true

func hide_specialization_panel():
	if specialization_panel:
		if specialization_panel.has_method("hide_panel"):
			specialization_panel.hide_panel()
		else:
			specialization_panel.visible = false

func hide_all_panels():
	hide_upgrade_panel()
	hide_market_panel()
	hide_hero_hall_panel()
	hide_specialization_panel()

func try_upgrade_selected():
	if selected_building and selected_building.has_method("upgrade"):
		if selected_building.upgrade():
			# Rafraîchir l'affichage après amélioration
			show_appropriate_panel()

func _input(event: InputEvent):
	# Désélectionner avec clic droit ou Échap
	if selected_building:
		if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
			deselect_building()
