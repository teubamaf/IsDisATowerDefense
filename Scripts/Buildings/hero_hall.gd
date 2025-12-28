extends Building

@export var hero_scene: PackedScene  # Scène du héros à acheter
@export var hero_cost_gold: float = 500.0
@export var hero_cost_wood: float = 200.0
@export var hero_cost_stone: float = 100.0

var current_hero: Node2D = null
var hero_spawn_position: Vector2

func _ready():
	super._ready()
	building_type = BuildingType.HERO_HALL  # Ou créer un nouveau type HERO_HALL
	hero_spawn_position = global_position + Vector2(0, -80)  # Devant le hall

func get_info_text() -> String:
	var base_text = super.get_info_text()
	if current_hero:
		base_text += "\n\nHéros actif"
	else:
		base_text += "\n\nAcheter Héros: %.0f Or, %.0f Bois, %.0f Pierre" % [hero_cost_gold, hero_cost_wood, hero_cost_stone]
	return base_text

func purchase_hero() -> bool:
	if current_hero and is_instance_valid(current_hero):
		print("Un héros est déjà actif !")
		return false
	
	if not GameManager.can_afford(hero_cost_gold, hero_cost_wood, hero_cost_stone):
		print("Ressources insuffisantes pour acheter un héros")
		return false
	
	if not hero_scene:
		print("Erreur: Scène de héros non définie")
		return false
	
	# Dépenser les ressources
	GameManager.spend_resources(hero_cost_gold, hero_cost_wood, hero_cost_stone)
	
	# Créer le héros
	current_hero = hero_scene.instantiate()
	current_hero.global_position = hero_spawn_position
	current_hero.add_to_group("heroes")
	
	# Ajouter au parent
	var parent_node = get_tree().get_first_node_in_group("game") or get_tree().current_scene
	if parent_node:
		parent_node.add_child(current_hero)
	
	# Connecter le signal de mort du héros
	if current_hero.has_signal("hero_died"):
		current_hero.hero_died.connect(_on_hero_died)
	
	print("Héros acheté et déployé !")
	return true

func _on_hero_died():
	current_hero = null
	print("Le héros est mort. Vous pouvez en acheter un nouveau.")
