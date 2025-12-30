extends Area2D

## Arcane Barrage - Evolved Magic Missile
## Fires 8 missiles in rapid succession with powerful homing

var level = 5  # Evolution level
var hp = 2  # Pierces through 2 enemies
var speed = 280.0
var damage = 18
var knockback_amount = 50
var attack_size = 1.3
var homing_strength = 10.0  # Very strong homing

var target: Node2D = null
var velocity := Vector2.ZERO
var lifetime := 4.0
var time_alive := 0.0
var trail_particles: GPUParticles2D = null

@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite = $Sprite2D

signal remove_from_array(object)

func _ready():
	add_to_group("attack")
	
	scale = Vector2.ONE * attack_size
	
	# Bright golden/arcane color
	modulate = Color(1.0, 0.8, 0.3, 1.0)
	
	# Find initial target
	find_target()
	
	# Initial velocity toward target or random direction
	if target and is_instance_valid(target):
		velocity = global_position.direction_to(target.global_position) * speed
	else:
		velocity = Vector2.RIGHT.rotated(randf() * TAU) * speed
	
	# Create persistent trail
	spawn_trail()

func _physics_process(delta):
	time_alive += delta
	if time_alive >= lifetime:
		finish()
		return
	
	# Update target if current one is invalid
	if not target or not is_instance_valid(target):
		find_target()
	
	# Very strong homing
	if target and is_instance_valid(target):
		var desired_direction = global_position.direction_to(target.global_position)
		var current_direction = velocity.normalized()
		var new_direction = current_direction.lerp(desired_direction, homing_strength * delta)
		velocity = new_direction * speed
	
	# Move
	position += velocity * delta
	
	# Rotate sprite to face movement direction
	rotation = velocity.angle()
	
	# Pulsing glow effect
	var pulse = 1.0 + sin(time_alive * 10.0) * 0.2
	modulate = Color(1.0 * pulse, 0.8 * pulse, 0.3, 1.0)

func find_target():
	var enemies = get_tree().get_nodes_in_group("enemy")
	var closest_dist := 600.0  # Longer range
	target = null
	
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			target = enemy

func spawn_trail():
	trail_particles = ParticleFactory.spawn_weapon_trail(self, Color(1.0, 0.8, 0.3, 1.0))
	trail_particles.amount = 15
	trail_particles.lifetime = 0.4

func enemy_hit(body):
	if body.is_in_group("enemy") or body.get_parent().is_in_group("enemy"):
		var enemy = body
		if enemy.has_method("_on_hurt_box_hurt"):
			var angle = velocity.normalized()
			enemy._on_hurt_box_hurt(damage, angle, knockback_amount)
		
		# Spawn bright hit particles
		ParticleFactory.spawn_hit_particles(get_parent(), global_position, 8, Color(1.0, 0.8, 0.3))
		
		# Brief screen shake
		var camera = get_viewport().get_camera_2d()
		if camera and camera.has_method("shake"):
			camera.shake(2.0, 0.1)
		
		hp -= 1
		if hp <= 0:
			# Explosion effect on final hit
			ParticleFactory.spawn_death_particles(get_parent(), global_position, 0.5)
			finish()

func finish():
	emit_signal("remove_from_array", self)
	if trail_particles and is_instance_valid(trail_particles):
		trail_particles.emitting = false
	queue_free()

func _on_timer_timeout():
	finish()
