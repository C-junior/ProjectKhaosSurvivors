extends Area2D

## Fire Ring - Orbits around player, burns enemies on contact
## Classic "garlic" style defensive weapon

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

@onready var player = get_tree().get_first_node_in_group("player")
@onready var damage_timer = $DamageTimer

var enemies_in_range := []

signal remove_from_array(object)

func _ready():
	add_to_group("attack")
	
	match level:
		1:
			damage = 3
			orbit_radius = 50.0
			attack_size = 1.0 * (1 + player.spell_size)
		2:
			damage = 4
			orbit_radius = 60.0
			attack_size = 1.1 * (1 + player.spell_size)
		3:
			damage = 5
			orbit_radius = 70.0
			orbit_speed = 200.0
			attack_size = 1.2 * (1 + player.spell_size)
		4:
			damage = 6
			orbit_radius = 80.0
			orbit_speed = 220.0
			attack_size = 1.3 * (1 + player.spell_size)
	
	scale = Vector2.ONE * attack_size
	
	# Start damage tick timer
	damage_timer.wait_time = tick_rate
	damage_timer.start()
	
	# Offset angle for multiple rings
	current_angle = orbit_index * (360.0 / 3.0)

func update_fire_ring():
	level = player.firering_level
	_ready()

func _physics_process(delta):
	if not player:
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

func _on_body_entered(body):
	if body.is_in_group("enemy") or body.get_parent().is_in_group("enemy"):
		if not enemies_in_range.has(body):
			enemies_in_range.append(body)

func _on_body_exited(body):
	if enemies_in_range.has(body):
		enemies_in_range.erase(body)

func _on_damage_timer_timeout():
	# Deal damage to all enemies in range
	for enemy in enemies_in_range:
		if is_instance_valid(enemy) and enemy.has_method("_on_hurt_box_hurt"):
			var angle_to_enemy = global_position.direction_to(enemy.global_position)
			enemy._on_hurt_box_hurt(damage, angle_to_enemy, knockback_amount)
