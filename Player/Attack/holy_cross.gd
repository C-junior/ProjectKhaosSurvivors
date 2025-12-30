extends Area2D

## Holy Cross - Boomerang weapon that returns to player
## Creates satisfying "there and back" damage pattern

var level = 1
var hp = 9999
var speed = 150.0
var damage = 8
var knockback_amount = 80
var attack_size = 1.0
var return_speed_mult = 1.5

var target = Vector2.ZERO
var angle = Vector2.ZERO
var is_returning := false
var max_distance := 200.0
var traveled_distance := 0.0
var spin_speed := 720.0  # Degrees per second

@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite = $Sprite2D

signal remove_from_array(object)

func _ready():
	match level:
		1:
			damage = 8
			speed = 150.0
			max_distance = 200.0
			return_speed_mult = 1.75  # Up from 1.5
			attack_size = 1.0 * (1 + player.spell_size)
		2:
			damage = 11
			speed = 175.0
			max_distance = 250.0
			return_speed_mult = 1.85
			attack_size = 1.05 * (1 + player.spell_size)
		3:
			damage = 14
			speed = 200.0
			max_distance = 300.0
			return_speed_mult = 2.0  # Much faster return
			attack_size = 1.1 * (1 + player.spell_size)
		4:
			damage = 18
			speed = 220.0
			max_distance = 350.0
			return_speed_mult = 2.25  # Very fast return
			attack_size = 1.2 * (1 + player.spell_size)
	
	# Initial direction toward target or random
	if target != Vector2.ZERO:
		angle = global_position.direction_to(target)
	else:
		angle = Vector2.RIGHT.rotated(randf() * TAU)
	
	# Scale based on level
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * attack_size, 0.2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _physics_process(delta):
	# Spin the sprite
	if sprite:
		sprite.rotation_degrees += spin_speed * delta
	
	if not is_returning:
		# Move outward
		position += angle * speed * delta
		traveled_distance += speed * delta
		
		# Check if should return
		if traveled_distance >= max_distance:
			is_returning = true
	else:
		# Return to player
		var to_player = global_position.direction_to(player.global_position)
		position += to_player * speed * return_speed_mult * delta
		
		# Check if reached player
		if global_position.distance_to(player.global_position) < 20:
			emit_signal("remove_from_array", self)
			queue_free()

func enemy_hit(_charge = 1):
	# Holy Cross doesn't despawn on hit - it keeps going
	pass

func _on_timer_timeout():
	emit_signal("remove_from_array", self)
	queue_free()
