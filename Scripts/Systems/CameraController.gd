extends Camera2D

# Vitesse de déplacement avec les touches
@export var move_speed: float = 600.0
@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.3
@export var max_zoom: float = 2.0

# Déplacement avec la souris (drag)
var is_dragging: bool = false
var drag_start_mouse_pos: Vector2 = Vector2.ZERO
var drag_start_camera_pos: Vector2 = Vector2.ZERO

# Limites de la caméra (optionnel)
@export var use_custom_limits: bool = true
@export var custom_limit_size: float = 2000.0

func _ready():
	# S'assurer que la caméra est active
	make_current()

func _process(delta: float):
	# Déplacement avec WASD ou les flèches
	var input_dir = Vector2.ZERO

	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		input_dir.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		input_dir.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		input_dir.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		input_dir.y += 1

	if input_dir != Vector2.ZERO:
		# Ajuster la vitesse selon le zoom (plus dézoomé = plus rapide)
		var adjusted_speed = move_speed / zoom.x
		position += input_dir.normalized() * adjusted_speed * delta

	# Appliquer les limites
	if use_custom_limits:
		position.x = clamp(position.x, -custom_limit_size, custom_limit_size)
		position.y = clamp(position.y, -custom_limit_size, custom_limit_size)

func _input(event: InputEvent):
	# Drag avec le clic du milieu ou clic gauche + Alt
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_MIDDLE:
			if event.pressed:
				start_drag()
			else:
				stop_drag()

		# Zoom avec la molette
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_in()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_out()

	# Mouvement de la souris pendant le drag
	if event is InputEventMouseMotion and is_dragging:
		var delta = event.relative / zoom
		position -= delta

		# Appliquer les limites
		if use_custom_limits:
			position.x = clamp(position.x, -custom_limit_size, custom_limit_size)
			position.y = clamp(position.y, -custom_limit_size, custom_limit_size)

func start_drag():
	is_dragging = true
	drag_start_mouse_pos = get_viewport().get_mouse_position()
	drag_start_camera_pos = position

func stop_drag():
	is_dragging = false

func zoom_in():
	var new_zoom = zoom + Vector2(zoom_speed, zoom_speed)
	zoom = new_zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

func zoom_out():
	var new_zoom = zoom - Vector2(zoom_speed, zoom_speed)
	zoom = new_zoom.clamp(Vector2(min_zoom, min_zoom), Vector2(max_zoom, max_zoom))

# Fonction pour recentrer la caméra
func center_on_position(target_pos: Vector2, animate: bool = true):
	if animate:
		var tween = create_tween()
		tween.tween_property(self, "position", target_pos, 0.3).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		position = target_pos

func reset_to_origin():
	center_on_position(Vector2.ZERO)
