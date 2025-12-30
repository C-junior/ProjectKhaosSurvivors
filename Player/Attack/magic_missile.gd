extends Area2D

## Magic Missile - Homing projectile weapon
## Auto-targets and homes in on nearest enemy

var level = 1
var hp = 1
var speed = 200.0
var damage = 6
var knockback_amount = 30
var attack_size = 1.0
var homing_strength = 5.0  # How fast it turns

var target: Node2D = null
var velocity := Vector2.ZERO
var lifetime := 3.0
var time_alive := 0.0

@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite = $Sprite2D

signal remove_from_array(object)

func _ready():
	add_to_group("attack")
	
	match level:
		1:
			damage = 6
			speed = 200.0
			homing_strength = 5.0
			attack_size = 1.0 * (1 + player.spell_size)
		2:
			damage = 8
			speed = 220.0
			homing_strength = 6.0
			attack_size = 1.05 * (1 + player.spell_size)
		3:
			damage = 10
			speed = 240.0
			homing_strength = 7.0
			attack_size = 1.1 * (1 + player.spell_size)
		4:
			damage = 14
			speed = 260.0
			homing_strength = 8.0
			attack_size = 1.15 * (1 + player.spell_size)
	
	scale = Vector2.ONE * attack_size
	
	# Purple/arcane color
	modulate = Color(0.8, 0.5, 1.0, 1.0)
	
	# Find initial target
	find_target()
	
	# Initial velocity toward target or random direction
	if target and is_instance_valid(target):
		velocity = global_position.direction_to(target.global_position) * speed
	else:
		velocity = Vector2.RIGHT.rotated(randf() * TAU) * speed

func _physics_process(delta):
	time_alive += delta
	if time_alive >= lifetime:
		finish()
		return
	
	# Update target if current one is invalid
	if not target or not is_instance_valid(target):
		find_target()
	
	# Home in on target
	if target and is_instance_valid(target):
		var desired_direction = global_position.direction_to(target.global_position)
		var current_direction = velocity.normalized()
		var new_direction = current_direction.lerp(desired_direction, homing_strength * delta)
		velocity = new_direction * speed
	
	# Move
	position += velocity * delta
	
	# Rotate sprite to face movement direction
	rotation = velocity.angle()
	
	# Trail effect - spawn particles occasionally
	if int(time_alive * 20) % 3 == 0:
		spawn_trail_particle()

func find_target():
	var enemies = get_tree().get_nodes_in_group("enemy")
	var closest_dist := 500.0
	target = null
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			target = enemy

func spawn_trail_particle():
	# Simple trail effect
	var trail = Sprite2D.new()
	trail.texture = sprite.texture if sprite and sprite.texture else null
	trail.global_position = global_position
	trail.rotation = rotation
	trail.scale = scale * 0.6
	trail.modulate = Color(0.6, 0.3, 0.9, 0.5)
	get_parent().add_child(trail)
	
	# Fade and shrink
	var tween = trail.create_tween()
	tween.set_parallel(true)
	tween.tween_property(trail, "modulate:a", 0.0, 0.3)
	tween.tween_property(trail, "scale", Vector2.ZERO, 0.3)
	tween.set_parallel(false)
	tween.tween_callback(trail.queue_free)

func enemy_hit(body):
	if body.is_in_group("enemy") or body.get_parent().is_in_group("enemy"):
		var enemy = body
		if enemy.has_method("_on_hurt_box_hurt"):
			var angle = velocity.normalized()
			enemy._on_hurt_box_hurt(damage, angle, knockback_amount)
		
		# Spawn hit particles
		ParticleFactory.spawn_hit_particles(get_parent(), global_position, 5, Color(0.8, 0.5, 1.0))
		
		hp -= 1
		if hp <= 0:
			finish()

func finish():
	emit_signal("remove_from_array", self)
	queue_free()

func _on_timer_timeout():
	finish()
