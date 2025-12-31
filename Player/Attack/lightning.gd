extends Area2D

## Lightning - Chain lightning that jumps between enemies
## High damage, satisfying visual chain effect

var level = 1
var damage = 12
var knockback_amount = 50
var chain_count = 2  # How many enemies it jumps to
var chain_range = 100.0  # Max distance to next enemy
var chain_delay = 0.1  # Seconds between chains

var current_target: Node2D = null
var hit_enemies := []
var chains_remaining := 0

@onready var player = get_tree().get_first_node_in_group("player")
@onready var line = $Line2D

signal remove_from_array(object)

func _ready():
	add_to_group("attack")
	
	match level:
		1:
			damage = 12
			chain_count = 2
			chain_range = 250.0  # Up from 200, +50%
		2:
			damage = 16
			chain_count = 3
			chain_range = 325.0  # Up from 250
		3:
			damage = 20
			chain_count = 4
			chain_range = 400.0  # Up from 300
		4:
			damage = 25
			chain_count = 6  # Up from 5
			chain_range = 500.0  # Up from 350, +50%
	
	chains_remaining = chain_count
	
	# Start chain from player to first target
	if current_target and is_instance_valid(current_target):
		start_chain(player.global_position, current_target)

func start_chain(from_pos: Vector2, target: Node2D):
	if not is_instance_valid(target):
		finish()
		return
	
	global_position = from_pos
	
	# Visual lightning line
	if line and is_instance_valid(target):
		line.clear_points()
		line.add_point(Vector2.ZERO)
		
		# Add jagged points for lightning effect
		var to_pos = target.global_position - global_position
		var segments = 5
		for i in range(1, segments):
			var t = float(i) / float(segments)
			var point = to_pos * t
			# Random offset for jagged look
			point += Vector2(randf_range(-8, 8), randf_range(-8, 8))
			line.add_point(point)
		
		line.add_point(to_pos)
	
	# Deal damage - check validity again before accessing
	if is_instance_valid(target) and target.has_method("_on_hurt_box_hurt"):
		var angle = from_pos.direction_to(target.global_position)
		target._on_hurt_box_hurt(damage, angle, knockback_amount)
		
		# Spawn damage number
		var damage_num_scene = preload("res://Utility/damage_number.tscn")
		var damage_num = damage_num_scene.instantiate()
		damage_num.global_position = target.global_position + Vector2(0, -10)
		damage_num.damage_amount = damage
		damage_num.damage_type = "lightning"
		get_tree().current_scene.add_child(damage_num)
	
	hit_enemies.append(target)
	chains_remaining -= 1
	
	# Flash effect
	modulate = Color(1.5, 1.5, 2.0, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	# Chain to next enemy
	if chains_remaining > 0:
		await get_tree().create_timer(chain_delay).timeout
		# Check if we're still valid after the await
		if not is_inside_tree():
			return
		var next_target = find_next_target(target.global_position if is_instance_valid(target) else global_position)
		if next_target:
			start_chain(target.global_position if is_instance_valid(target) else global_position, next_target)
		else:
			await get_tree().create_timer(0.2).timeout
			finish()
	else:
		await get_tree().create_timer(0.2).timeout
		finish()

func find_next_target(from_pos: Vector2) -> Node2D:
	var closest_enemy: Node2D = null
	var closest_dist: float = chain_range
	
	# Get all enemies
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy in hit_enemies:
			continue
		if not is_instance_valid(enemy):
			continue
		
		var dist = from_pos.distance_to(enemy.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest_enemy = enemy
	
	return closest_enemy

func finish():
	emit_signal("remove_from_array", self)
	
	# Fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.2)
	tween.tween_callback(queue_free)
