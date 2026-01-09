extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

func _ready():
	animation_player.animation_finished.connect(_on_animation_finished)
	animation_player.play("explosion")

func _on_animation_finished(_anim_name: String):
	queue_free()
