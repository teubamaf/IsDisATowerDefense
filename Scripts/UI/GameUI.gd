extends CanvasLayer

# Références aux éléments d'UI
@onready var gold_label = $MarginContainer/TopBar/VBoxContainer/HBoxContainer/GoldLabel
@onready var wood_label = $MarginContainer/TopBar/VBoxContainer/HBoxContainer/WoodLabel
@onready var stone_label = $MarginContainer/TopBar/VBoxContainer/HBoxContainer/StoneLabel
@onready var wave_timer_label = $MarginContainer/TopBar/VBoxContainer/WaveTimerLabel
@onready var castle_hp_bar = $MarginContainer/TopBar/VBoxContainer/CastleHPBar
@onready var wave_label = $MarginContainer/TopBar/VBoxContainer/WaveLabel

# Panel de construction
@onready var build_panel = $BuildPanel
@onready var mine_button = $BuildPanel/VBoxContainer/MineButton
@onready var sawmill_button = $BuildPanel/VBoxContainer/SawmillButton
@onready var market_button = $BuildPanel/VBoxContainer/MarketButton
@onready var tower_button = $BuildPanel/VBoxContainer/TowerButton
@onready var hero_hall_button = $BuildPanel/VBoxContainer/HeroHallButton

# Panel d'information
@onready var info_label = $InfoPanel/InfoLabel

# Panel en bas à droite
@onready var expand_button = $BottomRightPanel/VBoxContainer/ExpandButton
@onready var upgrade_button = $BottomRightPanel/VBoxContainer/UpgradeButton
@onready var skill_tree_button = $BottomRightPanel/VBoxContainer/SkillTreeButton
@onready var prestige_button = $BottomRightPanel/VBoxContainer/PrestigeButton

# Panel d'amélioration de bâtiment
@onready var upgrade_panel = $UpgradePanel
@onready var upgrade_panel_info = $UpgradePanel/VBoxContainer/InfoLabel
@onready var upgrade_panel_button = $UpgradePanel/VBoxContainer/UpgradeButton
@onready var upgrade_panel_close = $UpgradePanel/VBoxContainer/CloseButton

# Référence au BuildingPlacer, ChunkGrid et BuildingManager
var building_placer: Node = null
var chunk_grid: Node = null
var building_manager: Node = null

func _ready():
	print("🖥️ GameUI: Initialisation")
	print("🖥️ GameManager disponible:", GameManager != null)

	# Connecter aux signaux du GameManager
	GameManager.resources_changed.connect(_on_resources_changed)
	GameManager.castle_hp_changed.connect(_on_castle_hp_changed)
	GameManager.wave_started.connect(_on_wave_started)
	GameManager.wave_completed.connect(_on_wave_completed)
	GameManager.game_over.connect(_on_game_over)

	print("🖥️ GameUI: Signaux connectés")

	# Trouver le BuildingPlacer, ChunkGrid et BuildingManager
	await get_tree().process_frame
	building_placer = get_tree().get_first_node_in_group("building_placer")
	chunk_grid = get_tree().get_first_node_in_group("chunk_grid")
	building_manager = get_tree().get_first_node_in_group("building_manager")

	# Configuration des boutons de construction
	if mine_button:
		mine_button.pressed.connect(func(): request_build(1))
	if sawmill_button:
		sawmill_button.pressed.connect(func(): request_build(2))
	if market_button:
		market_button.pressed.connect(func(): request_build(3))
	if tower_button:
		tower_button.pressed.connect(func(): request_build(4))
	if hero_hall_button:
		hero_hall_button.pressed.connect(func(): request_build(5))

	# Configuration des boutons en bas à droite
	if expand_button:
		expand_button.pressed.connect(_on_expand_button_pressed)
	if upgrade_button:
		upgrade_button.pressed.connect(_on_upgrade_button_pressed)
	if skill_tree_button:
		skill_tree_button.pressed.connect(_on_skill_tree_button_pressed)
	if prestige_button:
		prestige_button.pressed.connect(_on_prestige_button_pressed)

	# Configuration des boutons du panneau d'amélioration
	if upgrade_panel_button:
		upgrade_panel_button.pressed.connect(_on_building_upgrade_pressed)
	if upgrade_panel_close:
		upgrade_panel_close.pressed.connect(_on_building_upgrade_close_pressed)

	# Initialisation
	print("🖥️ GameUI: Mise à jour initiale de l'UI")
	update_ui()
	print("🖥️ GameUI: Ready terminé")

func _process(_delta: float):
	# Mettre à jour le timer de vague
	if wave_timer_label and not GameManager.wave_in_progress:
		wave_timer_label.text = "Prochaine vague: " + GameManager.get_time_until_wave_string()

	if wave_label:
		if GameManager.wave_in_progress:
			wave_label.text = "VAGUE %d EN COURS" % GameManager.wave_number
			wave_label.add_theme_color_override("font_color", Color.RED)
		else:
			wave_label.text = "Vague %d" % GameManager.wave_number
			wave_label.add_theme_color_override("font_color", Color.WHITE)

func update_ui():
	_on_resources_changed()
	_on_castle_hp_changed(GameManager.castle_hp, GameManager.castle_max_hp)

func _on_resources_changed():
	print("🖥️ GameUI: _on_resources_changed appelé - Or:", GameManager.gold, " Bois:", GameManager.wood, " Pierre:", GameManager.stone)
	if gold_label:
		gold_label.text = "Or: %d (+%.1f/s)" % [int(GameManager.gold), GameManager.gold_per_second]
		print("   gold_label mis à jour:", gold_label.text)
	else:
		print("   ⚠️ gold_label est null!")
	if wood_label:
		wood_label.text = "Bois: %d (+%.1f/s)" % [int(GameManager.wood), GameManager.wood_per_second]
	else:
		print("   ⚠️ wood_label est null!")
	if stone_label:
		stone_label.text = "Pierre: %d (+%.1f/s)" % [int(GameManager.stone), GameManager.stone_per_second]
	else:
		print("   ⚠️ stone_label est null!")

func _on_castle_hp_changed(current_hp: float, max_hp: float):
	if castle_hp_bar:
		castle_hp_bar.max_value = max_hp
		castle_hp_bar.value = current_hp

		# Changer la couleur selon les PV
		var hp_ratio = current_hp / max_hp
		if hp_ratio > 0.5:
			castle_hp_bar.modulate = Color.GREEN
		elif hp_ratio > 0.25:
			castle_hp_bar.modulate = Color.YELLOW
		else:
			castle_hp_bar.modulate = Color.RED

func _on_wave_started(wave_num: int):
	show_notification("Vague %d commence !" % wave_num, Color.RED)

func _on_wave_completed(wave_num: int):
	show_notification("Vague %d terminée !" % wave_num, Color.GREEN)

func _on_game_over():
	show_notification("CHÂTEAU DÉTRUIT ! Prestige disponible...", Color.RED)
	# Ici on pourrait afficher un écran de prestige

func show_notification(text: String, color: Color):
	if info_label:
		info_label.text = text
		info_label.add_theme_color_override("font_color", color)

		# Faire disparaître après quelques secondes
		await get_tree().create_timer(3.0).timeout
		if info_label:
			info_label.text = ""

func request_build(building_type: int):
	print("🔨 Bouton cliqué ! Type: ", building_type)
	print("BuildingPlacer trouvé: ", building_placer != null)

	if building_placer and building_placer.has_method("start_build_mode"):
		print("Appel de start_build_mode...")
		building_placer.start_build_mode(building_type)
	else:
		print("❌ BuildingPlacer introuvable ou méthode manquante !")
		if building_placer:
			print("BuildingPlacer existe mais pas de méthode start_build_mode")

# Fonctions pour les boutons du panneau en bas à droite
func _on_expand_button_pressed():
	print("🌍 Bouton d'extension du territoire cliqué")
	if chunk_grid and chunk_grid.has_method("enter_expansion_mode"):
		chunk_grid.enter_expansion_mode()
		show_notification("Choisissez une zone adjacente à étendre (Échap ou clic droit pour annuler)", Color.CYAN)
	else:
		print("❌ ChunkGrid introuvable")

func _on_upgrade_button_pressed():
	print("⬆️ Bouton d'améliorations cliqué")
	show_notification("Système d'améliorations à venir...", Color.GRAY)

func _on_skill_tree_button_pressed():
	print("🌲 Bouton d'arbre de talents cliqué")
	show_notification("Arbre de talents à venir...", Color.GRAY)

func _on_prestige_button_pressed():
	print("⭐ Bouton de prestige cliqué")
	show_notification("Système de prestige à venir...", Color.GRAY)

# Fonctions pour le panneau d'amélioration de bâtiment
func _on_building_upgrade_pressed():
	if building_manager and building_manager.has_method("try_upgrade_selected"):
		building_manager.try_upgrade_selected()

func _on_building_upgrade_close_pressed():
	if building_manager and building_manager.has_method("deselect_building"):
		building_manager.deselect_building()
