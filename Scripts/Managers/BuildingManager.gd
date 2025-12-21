extends Node

# Gestionnaire de sélection et d'amélioration de bâtiments

var selected_building: Node2D = null

# Référence à l'UI
@onready var upgrade_panel: Control = null

func _ready():
	# Trouver le panneau d'amélioration dans l'UI
	await get_tree().process_frame
	upgrade_panel = get_node_or_null("/root/Game/GameUI/UpgradePanel")

	if upgrade_panel:
		upgrade_panel.visible = false

func select_building(building: Node2D, show_panel: bool = true):
	# Désélectionner le bâtiment précédent
	if selected_building and selected_building != building:
		if selected_building.has_method("set_selected"):
			selected_building.set_selected(false)

	# Sélectionner le nouveau bâtiment
	selected_building = building

	if selected_building and selected_building.has_method("set_selected"):
		selected_building.set_selected(true)

	# Afficher le panneau d'amélioration seulement si demandé
	if show_panel:
		show_upgrade_panel()
	else:
		hide_upgrade_panel()

func deselect_building():
	if selected_building and selected_building.has_method("set_selected"):
		selected_building.set_selected(false)

	selected_building = null
	hide_upgrade_panel()

func show_upgrade_panel():
	if not upgrade_panel or not selected_building:
		return

	upgrade_panel.visible = true

	# Mettre à jour les informations du panneau
	var info_label = upgrade_panel.get_node_or_null("InfoLabel")
	if info_label:
		info_label.text = selected_building.get_info_text()

	var upgrade_button = upgrade_panel.get_node_or_null("UpgradeButton")
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

func hide_upgrade_panel():
	if upgrade_panel:
		upgrade_panel.visible = false

func try_upgrade_selected():
	if selected_building and selected_building.has_method("upgrade"):
		if selected_building.upgrade():
			# Rafraîchir l'affichage après amélioration
			show_upgrade_panel()

func _input(event: InputEvent):
	# Désélectionner avec clic droit ou Échap
	if selected_building:
		if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
			deselect_building()
