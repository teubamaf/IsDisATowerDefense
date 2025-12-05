extends Control

# Panneaux du menu
@onready var main_buttons: VBoxContainer = $MainPanel/CenterContainer/MainButtons
@onready var save_panel: PanelContainer = $SavePanel
@onready var race_panel: PanelContainer = $RacePanel
@onready var settings_panel: PanelContainer = $SettingsPanel
@onready var credits_panel: PanelContainer = $CreditsPanel

# Boutons principaux
@onready var play_button: Button = $MainPanel/CenterContainer/MainButtons/Play
@onready var settings_button: Button = $MainPanel/CenterContainer/MainButtons/Settings
@onready var credits_button: Button = $MainPanel/CenterContainer/MainButtons/Credits
@onready var quit_button: Button = $MainPanel/CenterContainer/MainButtons/Quit

# Boutons de sauvegarde
@onready var save_buttons: Array[Button] = []

# Sélection de race
@onready var race_list: VBoxContainer = $RacePanel/MainVBox/HBoxContainer/RaceList
@onready var race_bonus_label: Label = $RacePanel/MainVBox/HBoxContainer/BonusPanel/VBoxContainer/BonusLabel
@onready var start_game_button: Button = $RacePanel/MainVBox/ButtonsHBox/StartGameButton

# Settings
@onready var resolution_option: OptionButton = $SettingsPanel/VBoxContainer/ResolutionOption
@onready var fullscreen_check: CheckButton = $SettingsPanel/VBoxContainer/FullscreenCheck

# Données
var selected_save: int = -1
var selected_race: int = -1

# Données des races
const RACE_DATA = {
	0: {"name": "Humains", "bonus": "+20% Generation d'Or\nBons commercants et diplomates"},
	1: {"name": "Orcs", "bonus": "+10% Degats du Chateau\nGuerriers feroces"},
	2: {"name": "Elfes", "bonus": "+15% Portee d'Attaque\nArchers d'elite"},
	3: {"name": "Nains", "bonus": "+30% PV des Structures\nBatisseurs legendaires"}
}

# Résolutions disponibles
const RESOLUTIONS = [
	Vector2i(1280, 720),
	Vector2i(1366, 768),
	Vector2i(1600, 900),
	Vector2i(1920, 1080),
	Vector2i(2560, 1440)
]

func _ready():
	# Cacher tous les panneaux secondaires
	save_panel.visible = false
	race_panel.visible = false
	settings_panel.visible = false
	credits_panel.visible = false

	# Connecter les boutons principaux
	play_button.pressed.connect(_on_play_pressed)
	settings_button.pressed.connect(_on_settings_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)

	# Initialiser les résolutions
	_setup_resolutions()

	# Connecter le bouton start game
	start_game_button.pressed.connect(_on_start_game_pressed)
	start_game_button.disabled = true

	# Connecter les boutons de sauvegarde
	for i in range(3):
		var save_btn = save_panel.get_node("VBoxContainer/Save" + str(i + 1))
		save_btn.pressed.connect(_on_save_selected.bind(i))
		save_buttons.append(save_btn)

	# Connecter les boutons de race
	for i in range(4):
		var race_btn = race_list.get_node("Race" + str(i))
		race_btn.pressed.connect(_on_race_selected.bind(i))

	# Connecter bouton retour de chaque panneau
	save_panel.get_node("VBoxContainer/BackButton").pressed.connect(_on_back_to_main)
	race_panel.get_node("MainVBox/ButtonsHBox/BackButton").pressed.connect(_on_back_to_saves)
	settings_panel.get_node("VBoxContainer/BackButton").pressed.connect(_on_back_to_main)
	credits_panel.get_node("VBoxContainer/BackButton").pressed.connect(_on_back_to_main)

	# Settings callbacks
	resolution_option.item_selected.connect(_on_resolution_selected)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)

func _setup_resolutions():
	resolution_option.clear()
	for res in RESOLUTIONS:
		resolution_option.add_item("%dx%d" % [res.x, res.y])

	# Sélectionner la résolution actuelle
	var current_res = DisplayServer.window_get_size()
	for i in range(RESOLUTIONS.size()):
		if RESOLUTIONS[i] == current_res:
			resolution_option.select(i)
			break

# Navigation principale
func _on_play_pressed():
	main_buttons.get_parent().get_parent().visible = false
	save_panel.visible = true

func _on_settings_pressed():
	main_buttons.get_parent().get_parent().visible = false
	settings_panel.visible = true

func _on_credits_pressed():
	main_buttons.get_parent().get_parent().visible = false
	credits_panel.visible = true

func _on_quit_pressed():
	get_tree().quit()

func _on_back_to_main():
	save_panel.visible = false
	race_panel.visible = false
	settings_panel.visible = false
	credits_panel.visible = false
	main_buttons.get_parent().get_parent().visible = true
	selected_save = -1
	selected_race = -1
	start_game_button.disabled = true

func _on_back_to_saves():
	race_panel.visible = false
	save_panel.visible = true
	selected_race = -1
	start_game_button.disabled = true

# Sélection de sauvegarde
func _on_save_selected(save_index: int):
	selected_save = save_index
	save_panel.visible = false
	race_panel.visible = true
	_update_race_selection()

# Sélection de race
func _on_race_selected(race_index: int):
	selected_race = race_index
	_update_race_selection()
	start_game_button.disabled = false

func _update_race_selection():
	# Mettre à jour le visuel des boutons de race
	for i in range(4):
		var race_btn = race_list.get_node("Race" + str(i))
		if i == selected_race:
			race_btn.add_theme_color_override("font_color", Color.YELLOW)
		else:
			race_btn.remove_theme_color_override("font_color")

	# Mettre à jour le label des bonus
	if selected_race >= 0:
		race_bonus_label.text = RACE_DATA[selected_race]["bonus"]
	else:
		race_bonus_label.text = "Selectionnez une race\npour voir ses bonus"

# Lancer le jeu
func _on_start_game_pressed():
	if selected_save >= 0 and selected_race >= 0:
		# Appliquer la race au GameManager
		GameManager.selected_race = selected_race
		# Charger la scène de jeu
		get_tree().change_scene_to_file("res://Scenes/Game.tscn")

# Settings
func _on_resolution_selected(index: int):
	var res = RESOLUTIONS[index]
	DisplayServer.window_set_size(res)
	# Centrer la fenêtre
	var screen_size = DisplayServer.screen_get_size()
	var window_pos = (screen_size - res) / 2
	DisplayServer.window_set_position(window_pos)

func _on_fullscreen_toggled(enabled: bool):
	if enabled:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
