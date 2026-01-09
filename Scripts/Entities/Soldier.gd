class_name Soldier
extends Enemy

# Le Soldier est plus rapide mais a moins de vie
func _ready():
	max_hp = 50.0
	speed = 60.0
	damage = 10.0
	gold_reward = 5.0
	super._ready()
