extends Area2D

## Inferno Aura - Evolved Fire Ring
## Multiple fire rings with expanding flame bursts and burn damage over time

var level = 5  # Evolution level
var hp = 9999
var damage = 10
var knockback_amount = 40
var attack_size = 2.0
var tick_rate = 0.3  # Faster damage ticks

var orbit_radius := 90.0
var orbit_speed := 300.0  # Much faster orbit
var current_angle := 0.0
var orbit_index := 0
var pulse_timer := 0.0
var pulse_interval := 2.0  # Seconds between big pulses

@onready var player = get_tree().get_first_node_in_group("player")
@onready var damage_timer = $DamageTimer

var enemies_in_range := []

signal remove_from_array(object)

func _ready():
	add_to_group("attack")
	
	attack_size = 2.0 * (1 + player.spell_size)
	scale = Vector2.ONE * attack_size
	
	# Start damage tick timer
	if damage_timer:
		damage_timer.wait_time = tick_rate
		damage_timer.start()
	
	# Offset angle for multiple rings
	current_angle = orbit_index * (360.0 / 4.0)
	
	# Fiery glow
	modulate = Color(1.2, 0.6, 0.2, 1.0)

func update_fire_ring():
	# Called when player upgrades - but this is evolved, so max stats
	pass

func _physics_process(delta):
	if not player:
		return
	
	# Faster orbit around player
	current_angle += orbit_speed * delta
	if current_angle >= 360.0:
		current_angle -= 360.0
	
	var offset = Vector2(
		cos(deg_to_rad(current_angle)) * orbit_radius,
		sin(deg_to_rad(current_angle)) * orbit_radius
	)
	global_position = player.global_position + offset
	
	# Pulsing scale effect
	var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.01) * 0.1
	scale = Vector2.ONE * attack_size * pulse
	
	# Periodic flame burst
	pulse_timer += delta
	if pulse_timer >= pulse_interval:
		pulse_timer = 0.0
		spawn_flame_burst()

func spawn_flame_burst():
	# Create expanding ring of fire that damages all nearby
	var burst = Area2D.new()
	burst.global_position = global_position
	burst.collision_layer = 0
	burst.collision_mask = 4
	
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 80 * attack_size
	shape.shape = circle
	burst.add_child(shape)
	
	get_parent().add_child(burst)
	
	# Deal burst damage to nearby enemies
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < 100 * attack_size:
				if enemy.has_method("_on_hurt_box_hurt"):
					var angle = global_position.direction_to(enemy.global_position)
					enemy._on_hurt_box_hurt(damage * 2, angle, knockback_amount * 1.5)
	
	# Visual expand and fade
	burst.scale = Vector2.ONE * 0.5
	var tween = burst.create_tween()
	tween.set_parallel(true)
	tween.tween_property(burst, "scale", Vector2.ONE * 2.0, 0.3)
	tween.tween_property(burst, "modulate:a", 0.0, 0.3)
	tween.set_parallel(false)
	tween.tween_callback(burst.queue_free)

func _on_body_entered(body):
	if body.is_in_group("enemy") or body.get_parent().is_in_group("enemy"):
		if not enemies_in_range.has(body):
			enemies_in_range.append(body)

func _on_body_exited(body):
	if enemies_in_range.has(body):
		enemies_in_range.erase(body)

func _on_damage_timer_timeout():
	# Deal damage to all enemies in range - with burn effect
	for enemy in enemies_in_range:
		if is_instance_valid(enemy) and enemy.has_method("_on_hurt_box_hurt"):
			var angle_to_enemy = global_position.direction_to(enemy.global_position)
			enemy._on_hurt_box_hurt(damage, angle_to_enemy, knockback_amount)
			
			# Visual burn effect on enemy
			if enemy.has_node("Sprite2D"):
				enemy.get_node("Sprite2D").modulate = Color(1.3, 0.8, 0.5, 1.0)
				var tween = enemy.create_tween()
				tween.tween_property(enemy.get_node("Sprite2D"), "modulate", Color.WHITE, 0.2)
