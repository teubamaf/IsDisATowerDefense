extends Node2D

# Script principal de la scène de jeu
# Gère l'initialisation des systèmes et des objets

@onready var castle = $Castle

# Mapping race int -> string
const RACE_NAMES = {
	0: "human",
	1: "orc",
	2: "elf",
	3: "dwarf"
}

func _ready():
	print("🎮 Game: Initialisation de la scène de jeu")

	# Initialiser le château avec la race sélectionnée
	if castle and castle.has_method("set_race"):
		var race_string = RACE_NAMES.get(GameManager.selected_race, "human")
		castle.set_race(race_string)
		print("🏰 Château initialisé avec la race: ", race_string)
