extends Area2D

## Fire Ring - Orbits around player, burns enemies on contact
## Activates for 8 seconds, then 2 second cooldown (10s total cycle)

var level = 1
var hp = 9999
var damage = 3
var knockback_amount = 20
var attack_size = 1.0
var tick_rate = 0.5  # Damage every X seconds

var orbit_radius := 50.0
var orbit_speed := 180.0  # Degrees per second
var current_angle := 0.0
var orbit_index := 0  # For multiple rings

# Active/Cooldown timing
var active_duration := 8.0  # Seconds the ring is active
var cooldown_duration := 2.0  # Seconds between cycles (10 total - 8 active = 2 cd)
var is_ring_active := true
var cycle_timer := 0.0

@onready var player = get_tree().get_first_node_in_group("player")
@onready var damage_timer = $DamageTimer

var enemies_in_range := []

signal remove_from_array(object)

func _ready():
	add_to_group("attack")
	
	match level:
		1:
			damage = 5
			orbit_radius = 50.0
			tick_rate = 0.5
			attack_size = 1.0 * (1 + player.spell_size)
		2:
			damage = 7
			orbit_radius = 60.0
			tick_rate = 0.45
			attack_size = 1.1 * (1 + player.spell_size)
		3:
			damage = 9
			orbit_radius = 70.0
			orbit_speed = 200.0
			tick_rate = 0.4
			attack_size = 1.2 * (1 + player.spell_size)
		4:
			damage = 12
			orbit_radius = 80.0
			orbit_speed = 220.0
			tick_rate = 0.35
			attack_size = 1.3 * (1 + player.spell_size)
	
	scale = Vector2.ONE * attack_size
	
	# Start damage tick timer
	damage_timer.wait_time = tick_rate
	damage_timer.start()
	
	# Offset angle for multiple rings
	current_angle = orbit_index * (360.0 / 3.0)
	
	# Start active
	is_ring_active = true
	cycle_timer = 0.0
	visible = true
	set_deferred("monitoring", true)

func update_fire_ring():
	level = player.firering_level
	_ready()

func _physics_process(delta):
	if not player:
		return
	
	# Handle active/cooldown cycle
	cycle_timer += delta
	
	if is_ring_active:
		# Ring is active - orbit and deal damage
		if cycle_timer >= active_duration:
			# Deactivate ring
			is_ring_active = false
			cycle_timer = 0.0
			_hide_ring()
	else:
		# Ring is on cooldown
		if cycle_timer >= cooldown_duration:
			# Reactivate ring
			is_ring_active = true
			cycle_timer = 0.0
			_show_ring()
	
	# Only orbit and deal damage when active
	if not is_ring_active:
		return
	
	# Orbit around player
	current_angle += orbit_speed * delta
	if current_angle >= 360.0:
		current_angle -= 360.0
	
	var offset = Vector2(
		cos(deg_to_rad(current_angle)) * orbit_radius,
		sin(deg_to_rad(current_angle)) * orbit_radius
	)
	global_position = player.global_position + offset

func _hide_ring():
	# Fade out effect
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		visible = false
		set_deferred("monitoring", false)
	)
	enemies_in_range.clear()

func _show_ring():
	# Spawn at player position and fade in
	global_position = player.global_position + Vector2(orbit_radius, 0).rotated(deg_to_rad(current_angle))
	visible = true
	modulate.a = 0.0
	set_deferred("monitoring", true)
	
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 1.0, 0.3)

func _on_body_entered(body):
	if not is_ring_active:
		return
	if body.is_in_group("enemy") or body.get_parent().is_in_group("enemy"):
		if not enemies_in_range.has(body):
			enemies_in_range.append(body)

func _on_body_exited(body):
	if enemies_in_range.has(body):
		enemies_in_range.erase(body)

func _on_damage_timer_timeout():
	if not is_ring_active:
		return
	# Deal damage to all enemies in range
	for enemy in enemies_in_range:
		if is_instance_valid(enemy) and enemy.has_method("_on_hurt_box_hurt"):
			var angle_to_enemy = global_position.direction_to(enemy.global_position)
			enemy._on_hurt_box_hurt(damage, angle_to_enemy, knockback_amount)
