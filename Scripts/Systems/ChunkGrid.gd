extends Node2D

# Système de grille pour l'expansion du territoire

# La taille d'un chunk = taille visible de la caméra au démarrage
# Avec une résolution de ~1152x648 visible (1440x810 / zoom 0.8) on arrondit
var CHUNK_SIZE: float = 1000.0  # Sera calculé dynamiquement

# Coûts d'achat
@export var chunk_gold_cost: float = 100.0
@export var chunk_wood_cost: float = 50.0

# Grille de chunks (true = débloqué, false = verrouillé)
var chunks_unlocked: Dictionary = {}
var chunk_visuals: Dictionary = {}

# Brouillard de guerre
var fog_visuals: Dictionary = {}
@onready var fog_container = $FogContainer

# Références visuelles
@onready var chunk_container = $ChunkContainer

# Mode d'extension
var expansion_mode: bool = false
var camera: Camera2D = null
var original_camera_zoom: Vector2 = Vector2.ONE
var original_camera_position: Vector2 = Vector2.ZERO

func _ready():
	# Créer les conteneurs si nécessaire
	if not has_node("FogContainer"):
		fog_container = Node2D.new()
		fog_container.name = "FogContainer"
		add_child(fog_container)

	# Trouver la caméra et calculer la taille du chunk
	await get_tree().process_frame
	camera = get_viewport().get_camera_2d()
	if camera:
		original_camera_zoom = camera.zoom
		original_camera_position = camera.position

		# Calculer la taille du chunk basée sur la vue de la caméra
		var viewport_size = get_viewport().get_visible_rect().size
		# On prend la plus petite dimension pour avoir un chunk carré
		CHUNK_SIZE = min(viewport_size.x, viewport_size.y) / camera.zoom.x
		print("📐 Taille du chunk calculée: ", CHUNK_SIZE, " pixels")

	# Débloquer le chunk central (0,0 en coordonnées de chunk = centre du monde)
	unlock_chunk(Vector2i(0, 0), true)

	# Créer les visuels
	create_chunk_visuals()
	create_fog_of_war()

	# Cacher la grille d'extension par défaut
	hide_grid()

func _input(event: InputEvent):
	# Sortir du mode d'extension avec Échap ou clic droit
	if expansion_mode:
		if event.is_action_pressed("ui_cancel") or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_RIGHT):
			exit_expansion_mode()

# === Conversion de coordonnées ===
func chunk_to_world(chunk_pos: Vector2i) -> Vector2:
	# Le chunk (0,0) est au centre du monde (0,0)
	return Vector2(chunk_pos.x * CHUNK_SIZE, chunk_pos.y * CHUNK_SIZE)

func world_to_chunk(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(floor(world_pos.x / CHUNK_SIZE + 0.5)),
		int(floor(world_pos.y / CHUNK_SIZE + 0.5))
	)

# === Gestion des chunks ===
func is_chunk_unlocked(chunk_pos: Vector2i) -> bool:
	return chunks_unlocked.get(chunk_pos, false)

func can_unlock_chunk(chunk_pos: Vector2i) -> bool:
	if is_chunk_unlocked(chunk_pos):
		return false

	# Vérifier si au moins un chunk adjacent est débloqué
	var adjacent = [
		chunk_pos + Vector2i(1, 0),
		chunk_pos + Vector2i(-1, 0),
		chunk_pos + Vector2i(0, 1),
		chunk_pos + Vector2i(0, -1)
	]

	for adj_pos in adjacent:
		if is_chunk_unlocked(adj_pos):
			return true

	return false

func try_unlock_chunk(chunk_pos: Vector2i):
	if not can_unlock_chunk(chunk_pos):
		print("Ce chunk ne peut pas être débloqué")
		return

	if GameManager.spend_resources(chunk_gold_cost, chunk_wood_cost, 0):
		unlock_chunk(chunk_pos)  # false par défaut = rafraîchir les visuels
		print("✅ Chunk débloqué à ", chunk_pos)

		if expansion_mode:
			exit_expansion_mode()
	else:
		print("❌ Ressources insuffisantes")

func unlock_chunk(chunk_pos: Vector2i, is_initial: bool = false):
	chunks_unlocked[chunk_pos] = true
	print("🔓 Chunk débloqué: ", chunk_pos, " (chunks débloqués: ", chunks_unlocked.keys(), ")")

	# Ne pas rafraîchir si c'est le déblocage initial (on le fera après)
	if not is_initial:
		refresh_all_visuals()

func refresh_all_visuals():
	# Nettoyer
	for child in chunk_container.get_children():
		child.queue_free()
	chunk_visuals.clear()

	for child in fog_container.get_children():
		child.queue_free()
	fog_visuals.clear()

	# Recréer
	create_chunk_visuals()
	create_fog_of_war()

# === Visuels de la grille d'extension ===
func create_chunk_visuals():
	# N'afficher que les chunks proches des zones débloquées
	var chunks_to_show: Array[Vector2i] = []

	# Ajouter tous les chunks débloqués
	for chunk_pos in chunks_unlocked.keys():
		if not chunk_pos in chunks_to_show:
			chunks_to_show.append(chunk_pos)

		# Ajouter les adjacents (pour pouvoir les acheter)
		for offset in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var adj = chunk_pos + offset
			if not adj in chunks_to_show:
				chunks_to_show.append(adj)

	# Créer les visuels
	for chunk_pos in chunks_to_show:
		create_chunk_visual(chunk_pos)

func create_chunk_visual(chunk_pos: Vector2i):
	var chunk_node = Node2D.new()
	var world_pos = chunk_to_world(chunk_pos)
	chunk_node.position = world_pos

	var half_size = CHUNK_SIZE / 2.0

	# Carré de fond
	var poly = Polygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(-half_size, -half_size),
		Vector2(half_size, -half_size),
		Vector2(half_size, half_size),
		Vector2(-half_size, half_size)
	])

	if is_chunk_unlocked(chunk_pos):
		poly.color = Color(0.2, 0.7, 0.3, 0.2)  # Vert transparent
	elif can_unlock_chunk(chunk_pos):
		poly.color = Color(0.3, 0.3, 0.6, 0.4)  # Bleu pour achetable
	else:
		poly.color = Color(0.1, 0.1, 0.1, 0.6)  # Gris foncé

	chunk_node.add_child(poly)

	# Bordure
	var border = Line2D.new()
	border.points = PackedVector2Array([
		Vector2(-half_size, -half_size),
		Vector2(half_size, -half_size),
		Vector2(half_size, half_size),
		Vector2(-half_size, half_size),
		Vector2(-half_size, -half_size)
	])
	border.width = 2.0

	if is_chunk_unlocked(chunk_pos):
		border.default_color = Color(0.4, 0.9, 0.4, 0.8)
	elif can_unlock_chunk(chunk_pos):
		border.default_color = Color(0.5, 0.5, 1.0, 0.8)
	else:
		border.default_color = Color(0.3, 0.3, 0.3, 0.5)

	chunk_node.add_child(border)

	# Label et bouton pour les chunks achetables
	if can_unlock_chunk(chunk_pos):
		var label = Label.new()
		label.text = "Acheter\n%d Or\n%d Bois" % [int(chunk_gold_cost), int(chunk_wood_cost)]
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.position = Vector2(-half_size, -half_size)
		label.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
		label.add_theme_color_override("font_color", Color.WHITE)
		chunk_node.add_child(label)

		# Zone cliquable
		var area = Area2D.new()
		var collision = CollisionShape2D.new()
		var shape = RectangleShape2D.new()
		shape.size = Vector2(CHUNK_SIZE, CHUNK_SIZE)
		collision.shape = shape
		area.add_child(collision)
		area.input_event.connect(func(_viewport, event, _shape_idx):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				try_unlock_chunk(chunk_pos)
		)
		chunk_node.add_child(area)

	chunk_container.add_child(chunk_node)
	chunk_visuals[chunk_pos] = chunk_node

# === Brouillard de guerre ===
func create_fog_of_war():
	# S'assurer que le FogContainer est visible
	if fog_container:
		fog_container.visible = true
		fog_container.z_index = 5  # Entre background (-100) et éléments de jeu
		print("🌫️ FogContainer configuré: visible=", fog_container.visible, ", z_index=", fog_container.z_index)

	# Au lieu de créer des centaines de tiles, créer seulement pour les zones adjacentes
	# Cela réduit drastiquement le nombre de tiles à créer
	var chunks_to_fog: Array[Vector2i] = []

	# Pour chaque chunk débloqué, ajouter les voisins non débloqués
	for unlocked_pos in chunks_unlocked.keys():
		for dx in range(-2, 3):  # 2 chunks autour
			for dy in range(-2, 3):
				var neighbor = unlocked_pos + Vector2i(dx, dy)
				if not is_chunk_unlocked(neighbor) and not neighbor in chunks_to_fog:
					chunks_to_fog.append(neighbor)

	print("🌫️ Création de ", chunks_to_fog.size(), " fog tiles")

	for chunk_pos in chunks_to_fog:
		create_fog_tile(chunk_pos)

func create_fog_tile(chunk_pos: Vector2i):
	if not fog_container:
		print("❌ ERREUR: fog_container est null!")
		return

	var fog_node = Polygon2D.new()
	var world_pos = chunk_to_world(chunk_pos)
	fog_node.position = world_pos
	fog_node.z_index = 100  # Z-index très élevé pour être sûr qu'il soit visible
	fog_node.name = "Fog_" + str(chunk_pos.x) + "_" + str(chunk_pos.y)

	var half_size = CHUNK_SIZE / 2.0
	fog_node.polygon = PackedVector2Array([
		Vector2(-half_size, -half_size),
		Vector2(half_size, -half_size),
		Vector2(half_size, half_size),
		Vector2(-half_size, half_size)
	])

	# Couleur de base
	fog_node.color = Color(0.08, 0.08, 0.15, 0.95)

	# Ajouter un shader de brouillard nuageux animé
	var shader_material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
shader_type canvas_item;

uniform float time_scale = 0.2;
uniform vec4 fog_color : source_color = vec4(0.05, 0.05, 0.12, 0.95);
uniform vec4 cloud_color : source_color = vec4(0.15, 0.15, 0.25, 1.0);

// Fonction de bruit simplifié
float noise(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float smoothNoise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);

	float a = noise(i);
	float b = noise(i + vec2(1.0, 0.0));
	float c = noise(i + vec2(0.0, 1.0));
	float d = noise(i + vec2(1.0, 1.0));

	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(vec2 p) {
	float value = 0.0;
	float amplitude = 0.5;
	for(int i = 0; i < 5; i++) {
		value += amplitude * smoothNoise(p);
		p *= 2.0;
		amplitude *= 0.5;
	}
	return value;
}

void fragment() {
	vec2 uv = UV * 2.5;
	float t = TIME * time_scale;

	// Premier calque de nuages qui se déplace lentement
	vec2 offset1 = vec2(t * 0.08, t * 0.05);
	float clouds1 = fbm(uv + offset1);

	// Deuxième calque de nuages plus rapide
	vec2 offset2 = vec2(-t * 0.12, t * 0.07);
	float clouds2 = fbm(uv * 1.3 + offset2);

	// Combiner les calques
	float clouds = (clouds1 * 0.6 + clouds2 * 0.4);

	// Créer des zones plus claires et plus sombres
	clouds = smoothstep(0.3, 0.8, clouds);

	// Mélanger entre la couleur de base et la couleur des nuages
	vec4 final_color = mix(fog_color, cloud_color, clouds * 0.3);

	// Ajouter une variation d'opacité pour l'effet nuageux
	final_color.a *= 0.85 + clouds * 0.15;

	COLOR = final_color;
}
"""
	shader_material.shader = shader
	fog_node.material = shader_material

	fog_container.add_child(fog_node)
	fog_visuals[chunk_pos] = fog_node

# === Mode d'extension ===
func show_grid():
	if chunk_container:
		chunk_container.visible = true

func hide_grid():
	if chunk_container:
		chunk_container.visible = false

func enter_expansion_mode():
	if expansion_mode:
		return

	expansion_mode = true

	if camera:
		original_camera_zoom = camera.zoom
		original_camera_position = camera.position

		var target_zoom = Vector2(0.35, 0.35)
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(camera, "zoom", target_zoom, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(camera, "position", Vector2.ZERO, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	show_grid()
	print("🌍 Mode d'extension activé")

func exit_expansion_mode():
	if not expansion_mode:
		return

	expansion_mode = false

	if camera:
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(camera, "zoom", original_camera_zoom, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		tween.tween_property(camera, "position", original_camera_position, 0.5).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	hide_grid()
	print("🌍 Mode d'extension désactivé")

# === Utilitaires ===
func is_position_in_unlocked_chunk(world_pos: Vector2) -> bool:
	var chunk_pos = world_to_chunk(world_pos)
	return is_chunk_unlocked(chunk_pos)
