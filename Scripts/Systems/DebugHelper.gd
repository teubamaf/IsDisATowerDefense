extends Node

# Script helper pour débugger et tester rapidement le jeu
# À attacher à la scène Game ou à utiliser comme autoload

func _init():
	print("🔧 DebugHelper: Script chargé (init)")

func _ready():
	print("=== Debug Helper Activé ===")
	print("Appuyez sur:")
	print("  U - Ajouter 100 de chaque ressource")
	print("  I - Déclencher une vague immédiatement")
	print("  O - Soigner le château à 100%")
	print("  P - Spawn 10 ennemis")
	print("  J - Ajouter 1000 or")
	print("  K - Tuer tous les ennemis")
	print("  L - Afficher les stats")

	# S'assurer que le node reçoit les inputs
	set_process(true)

func _process(_delta: float):
	# Détection directe des touches avec Input
	if Input.is_key_pressed(KEY_U):
		if not _u_pressed:
			_u_pressed = true
			add_resources()
	else:
		_u_pressed = false

	if Input.is_key_pressed(KEY_I):
		if not _i_pressed:
			_i_pressed = true
			trigger_wave()
	else:
		_i_pressed = false

	if Input.is_key_pressed(KEY_O):
		if not _o_pressed:
			_o_pressed = true
			heal_castle()
	else:
		_o_pressed = false

	if Input.is_key_pressed(KEY_P):
		if not _p_pressed:
			_p_pressed = true
			spawn_enemies()
	else:
		_p_pressed = false

	if Input.is_key_pressed(KEY_J):
		if not _j_pressed:
			_j_pressed = true
			add_gold()
	else:
		_j_pressed = false

	if Input.is_key_pressed(KEY_K):
		if not _k_pressed:
			_k_pressed = true
			kill_all_enemies()
	else:
		_k_pressed = false

	if Input.is_key_pressed(KEY_L):
		if not _l_pressed:
			_l_pressed = true
			print_stats()
	else:
		_l_pressed = false

# Variables pour éviter les répétitions
var _u_pressed = false
var _i_pressed = false
var _o_pressed = false
var _p_pressed = false
var _j_pressed = false
var _k_pressed = false
var _l_pressed = false

func add_resources():
	GameManager.add_gold(100)
	GameManager.add_wood(100)
	GameManager.add_stone(100)
	print("✅ +100 de chaque ressource ajouté")

func trigger_wave():
	if not GameManager.wave_in_progress:
		GameManager.start_wave()
		print("✅ Vague déclenchée manuellement")
	else:
		print("⚠️ Une vague est déjà en cours")

func heal_castle():
	GameManager.heal_castle(GameManager.castle_max_hp)
	print("✅ Château soigné à 100%")

func spawn_enemies():
	var wave_manager = get_tree().get_first_node_in_group("wave_manager")
	if wave_manager and wave_manager.has_method("spawn_enemy"):
		for i in range(10):
			wave_manager.spawn_enemy(GameManager.wave_number)
		print("✅ 10 ennemis spawnés")
	else:
		print("❌ WaveManager introuvable")

func add_gold():
	GameManager.add_gold(1000)
	print("✅ +1000 or ajouté")

func kill_all_enemies():
	var enemies = get_tree().get_nodes_in_group("enemies")
	var count = enemies.size()
	for enemy in enemies:
		if enemy.has_method("die"):
			enemy.die()
	print("✅ %d ennemis tués" % count)

func print_stats():
	print("\n=== STATISTIQUES DU JEU ===")
	print("Or: %.1f (+%.1f/s)" % [GameManager.gold, GameManager.gold_per_second])
	print("Bois: %.1f (+%.1f/s)" % [GameManager.wood, GameManager.wood_per_second])
	print("Pierre: %.1f (+%.1f/s)" % [GameManager.stone, GameManager.stone_per_second])
	print("Vague actuelle: %d" % GameManager.wave_number)
	print("Temps avant prochaine vague: %.1fs" % GameManager.time_until_next_wave)
	print("PV Château: %.0f / %.0f" % [GameManager.castle_hp, GameManager.castle_max_hp])
	print("Dégâts Château: %.1f" % GameManager.castle_damage)
	print("Portée Château: %.1f" % GameManager.castle_attack_range)

	var enemies = get_tree().get_nodes_in_group("enemies")
	print("Ennemis vivants: %d" % enemies.size())

	var resources = get_tree().get_nodes_in_group("collectable_resources")
	print("Ressources sur la carte: %d" % resources.size())
	print("==========================\n")
