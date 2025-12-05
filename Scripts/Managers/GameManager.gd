extends Node

# Singleton pour gérer l'état global du jeu

func _init():
	print("🎮 GameManager: Initialisation")

# Ressources
var gold: float = 1000.0
var wood: float = 1000.0
var stone: float = 1000.0

# Génération passive par seconde
var gold_per_second: float = 0.0
var wood_per_second: float = 0.0
var stone_per_second: float = 0.0

# Système de vagues
var wave_number: int = 0
var time_until_next_wave: float = 180.0  # 3 minutes
var wave_in_progress: bool = false

# Statistiques du château
var castle_max_hp: float = 1000.0
var castle_hp: float = 1000.0
var castle_damage: float = 10.0
var castle_attack_range: float = 200.0
var castle_attack_speed: float = 1.0  # Attaques par seconde

# Race sélectionnée (0=Humain, 1=Orc, 2=Elfe, 3=Nain)
var selected_race: int = 0

# Signaux pour notifier les changements
signal resources_changed
signal wave_started(wave_num: int)
signal wave_completed(wave_num: int)
signal castle_hp_changed(current_hp: float, max_hp: float)
signal game_over

func _ready():
	print("🎮 GameManager: Ready - Or:", gold, " Bois:", wood, " Pierre:", stone)
	# Appliquer les bonus de race
	apply_race_bonus()
	print("🎮 GameManager: Prêt à recevoir des connexions de signaux")

func _process(delta: float):
	# Génération passive de ressources
	if gold_per_second > 0:
		add_gold(gold_per_second * delta)
	if wood_per_second > 0:
		add_wood(wood_per_second * delta)
	if stone_per_second > 0:
		add_stone(stone_per_second * delta)

	# Timer des vagues
	if not wave_in_progress:
		time_until_next_wave -= delta
		if time_until_next_wave <= 0:
			start_wave()

func apply_race_bonus():
	match selected_race:
		0:  # Humains - +20% Génération Or
			gold_per_second *= 1.2
		1:  # Orcs - Bonus au combat
			castle_damage *= 1.1
		2:  # Elfes - Portée accrue
			castle_attack_range *= 1.15
		3:  # Nains - +30% PV Structure
			castle_max_hp *= 1.3
			castle_hp = castle_max_hp

# Gestion des ressources
func add_gold(amount: float):
	gold += amount
	resources_changed.emit()

func add_wood(amount: float):
	wood += amount
	resources_changed.emit()

func add_stone(amount: float):
	stone += amount
	resources_changed.emit()

func can_afford(gold_cost: float, wood_cost: float, stone_cost: float) -> bool:
	return gold >= gold_cost and wood >= wood_cost and stone >= stone_cost

func spend_resources(gold_cost: float, wood_cost: float, stone_cost: float) -> bool:
	if can_afford(gold_cost, wood_cost, stone_cost):
		gold -= gold_cost
		wood -= wood_cost
		stone -= stone_cost
		resources_changed.emit()
		return true
	return false

# Système de vagues
func start_wave():
	wave_number += 1
	wave_in_progress = true
	time_until_next_wave = 180.0  # Reset timer
	wave_started.emit(wave_number)
	print("Vague ", wave_number, " commence !")

func complete_wave():
	wave_in_progress = false
	var gems_reward = wave_number * 10
	add_gold(gems_reward)
	wave_completed.emit(wave_number)
	print("Vague ", wave_number, " terminée ! +", gems_reward, " or")

# Système de combat
func damage_castle(damage: float):
	castle_hp -= damage
	castle_hp = max(0, castle_hp)
	castle_hp_changed.emit(castle_hp, castle_max_hp)

	if castle_hp <= 0:
		trigger_game_over()

func heal_castle(amount: float):
	castle_hp = min(castle_max_hp, castle_hp + amount)
	castle_hp_changed.emit(castle_hp, castle_max_hp)

func trigger_game_over():
	print("Château détruit ! Prestige disponible...")
	game_over.emit()

# Amélioration du château
func upgrade_castle_hp(cost_gold: float, cost_stone: float, hp_increase: float) -> bool:
	if spend_resources(cost_gold, 0, cost_stone):
		castle_max_hp += hp_increase
		castle_hp = castle_max_hp
		castle_hp_changed.emit(castle_hp, castle_max_hp)
		return true
	return false

func upgrade_castle_damage(cost_gold: float, damage_increase: float) -> bool:
	if spend_resources(cost_gold, 0, 0):
		castle_damage += damage_increase
		return true
	return false

func get_time_until_wave_string() -> String:
	var minutes = int(time_until_next_wave) / 60
	var seconds = int(time_until_next_wave) % 60
	return "%02d:%02d" % [minutes, seconds]
