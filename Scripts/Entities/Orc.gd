class_name Orc
extends Enemy

# L'Orc a plus de vie mais est plus lent
func _ready():
	max_hp = 80.0
	speed = 35.0
	damage = 15.0
	gold_reward = 8.0
	super._ready()
