extends Area2D

## Maelstrom - Evolved Tornado (Tornado 4 + Scroll 4)
## A massive whirlwind that pulls enemies toward its center

var hp = 9999
var speed = 80.0  # Slower for better area control
var damage = 15
var attack_size = 1.8  # Much larger than regular tornado
var knockback_amount = 50
var pull_strength = 100.0  # How strongly it pulls enemies

var last_movement = Vector2.ZERO
var angle = Vector2.ZERO
var angle_less = Vector2.ZERO
var angle_more = Vector2.ZERO

var rotation_speed = 5.0
var damage_tick_timer := 0.0

signal remove_from_array(object)

@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	add_to_group("attack")
	
	# Apply player spell size bonus
	if player:
		attack_size *= (1 + player.spell_size)
	
	# Calculate movement angles based on last movement
	var move_to_less = Vector2.ZERO
	var move_to_more = Vector2.ZERO
	match last_movement:
		Vector2.UP, Vector2.DOWN:
			move_to_less = global_position + Vector2(randf_range(-1, -0.25), last_movement.y) * 500
			move_to_more = global_position + Vector2(randf_range(0.25, 1), last_movement.y) * 500
		Vector2.RIGHT, Vector2.LEFT:
			move_to_less = global_position + Vector2(last_movement.x, randf_range(-1, -0.25)) * 500
			move_to_more = global_position + Vector2(last_movement.x, randf_range(0.25, 1)) * 500
		Vector2(1, 1), Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1):
			move_to_less = global_position + Vector2(last_movement.x, last_movement.y * randf_range(0, 0.75)) * 500
			move_to_more = global_position + Vector2(last_movement.x * randf_range(0, 0.75), last_movement.y) * 500
	
	angle_less = global_position.direction_to(move_to_less)
	angle_more = global_position.direction_to(move_to_more)
	
	# Scale up with dramatic effect
	var initial_tween = create_tween().set_parallel(true)
	initial_tween.tween_property(self, "scale", Vector2(1, 1) * attack_size, 2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	initial_tween.tween_property(self, "modulate", Color(0.8, 0.5, 1.0, 1.0), 0.5)  # Purple tint
	var final_speed = speed
	speed = speed / 4.0
	initial_tween.tween_property(self, "speed", final_speed, 4).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	
	# Set movement pattern - serpentine motion
	var tween = create_tween()
	var set_angle = randi_range(0, 1)
	if set_angle == 1:
		angle = angle_less
		for i in range(6):
			tween.tween_property(self, "angle", angle_more if i % 2 == 0 else angle_less, 2)
	else:
		angle = angle_more
		for i in range(6):
			tween.tween_property(self, "angle", angle_less if i % 2 == 0 else angle_more, 2)

func _physics_process(delta):
	# Move forward
	position += angle * speed * delta
	
	# Rotate visually for effect
	rotation += rotation_speed * delta
	
	# Pull enemies toward center
	pull_nearby_enemies(delta)
	
	# Spawn vortex particles
	damage_tick_timer += delta
	if damage_tick_timer >= 0.2:
		damage_tick_timer = 0.0
		spawn_vortex_particles()

func pull_nearby_enemies(delta):
	var pull_radius = 120.0 * attack_size  # Larger pull area
	var enemies = get_tree().get_nodes_in_group("enemy")
	
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= pull_radius and dist > 10:  # Don't pull if too close
			# Calculate pull direction toward maelstrom center
			var pull_direction = global_position - enemy.global_position
			var pull_force = pull_strength * (1 - (dist / pull_radius))  # Stronger pull when closer
			
			# Apply pull to enemy velocity
			if enemy.has_method("apply_external_force"):
				enemy.apply_external_force(pull_direction.normalized() * pull_force * delta)
			elif "velocity" in enemy:
				enemy.velocity += pull_direction.normalized() * pull_force * delta

func spawn_vortex_particles():
	# Spawn swirling particles around the maelstrom
	for i in range(3):
		var particle = Sprite2D.new()
		var offset_angle = randf() * TAU
		var offset_dist = randf_range(20, 60) * attack_size
		particle.global_position = global_position + Vector2(cos(offset_angle), sin(offset_angle)) * offset_dist
		particle.scale = Vector2(0.3, 0.3) * attack_size
		particle.modulate = Color(0.7, 0.4, 1.0, 0.7)  # Purple particles
		get_parent().add_child(particle)
		
		# Spiral into center and fade
		var tween = particle.create_tween().set_parallel(true)
		tween.tween_property(particle, "global_position", global_position, 0.4)
		tween.tween_property(particle, "modulate:a", 0.0, 0.4)
		tween.tween_property(particle, "rotation", particle.rotation + TAU, 0.4)
		tween.chain().tween_callback(particle.queue_free)

func _on_timer_timeout():
	emit_signal("remove_from_array", self)
	queue_free()
