extends Area2D

## Storm Caller - Evolved Lightning
## Massive chain lightning that hits many more enemies with AOE damage

var level = 5  # Evolution level
var damage = 35
var knockback_amount = 80
var chain_count = 10  # Hits many more enemies
var chain_range = 400.0  # Much larger range
var chain_delay = 0.05  # Faster chains

var current_target: Node2D = null
var hit_enemies := []
var chains_remaining := 0
var storm_mode := false  # Triggers periodic auto-casts

@onready var player = get_tree().get_first_node_in_group("player")
@onready var line = $Line2D

signal remove_from_array(object)

func _ready():
	add_to_group("attack")
	
	chains_remaining = chain_count
	
	# Purple/electric color for evolved version
	modulate = Color(0.8, 0.5, 1.0, 1.0)
	
	# Start chain from player to first target
	if current_target and is_instance_valid(current_target):
		start_chain(player.global_position, current_target)

func start_chain(from_pos: Vector2, target: Node2D):
	if not is_instance_valid(target):
		finish()
		return
	
	global_position = from_pos
	
	# Visual lightning line with more intensity
	if line and is_instance_valid(target):
		line.clear_points()
		line.add_point(Vector2.ZERO)
		line.width = 4.0  # Thicker for evolved
		
		# More jagged points for intense lightning effect
		var to_pos = target.global_position - global_position
		var segments = 8
		for i in range(1, segments):
			var t = float(i) / float(segments)
			var point = to_pos * t
			# Larger random offset for more dramatic look
			point += Vector2(randf_range(-15, 15), randf_range(-15, 15))
			line.add_point(point)
		
		line.add_point(to_pos)
	
	# Deal damage with AOE
	if is_instance_valid(target):
		deal_aoe_damage(target)
	
	hit_enemies.append(target)
	chains_remaining -= 1
	
	# Intense flash effect
	modulate = Color(2.0, 1.5, 2.5, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(0.8, 0.5, 1.0, 1.0), 0.1)
	
	# Screen shake for powerful effect
	if chains_remaining == chain_count - 1:  # First hit
		var camera = get_viewport().get_camera_2d()
		if camera and camera.has_method("shake"):
			camera.shake(3.0, 0.3)
	
	# Chain to next enemy
	if chains_remaining > 0:
		await get_tree().create_timer(chain_delay).timeout
		if not is_inside_tree():
			return
		var next_target = find_next_target(target.global_position if is_instance_valid(target) else global_position)
		if next_target:
			start_chain(target.global_position if is_instance_valid(target) else global_position, next_target)
		else:
			await get_tree().create_timer(0.2).timeout
			finish()
	else:
		# Final chain - big explosion
		spawn_final_explosion()
		await get_tree().create_timer(0.3).timeout
		finish()

func deal_aoe_damage(target: Node2D):
	if not is_instance_valid(target):
		return
		
	# Damage primary target
	if target.has_method("_on_hurt_box_hurt"):
		var angle = global_position.direction_to(target.global_position)
		target._on_hurt_box_hurt(damage, angle, knockback_amount)
	
	# AOE damage to nearby enemies (half damage)
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy == target:
			continue
		if not is_instance_valid(enemy):
			continue
		
		var dist = target.global_position.distance_to(enemy.global_position)
		if dist < 60:  # AOE radius
			if enemy.has_method("_on_hurt_box_hurt"):
				var angle = target.global_position.direction_to(enemy.global_position)
				enemy._on_hurt_box_hurt(int(damage * 0.5), angle, knockback_amount * 0.5)

func spawn_final_explosion():
	# Create dramatic lightning explosion at last hit position
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(6.0, 0.5)
	
	# Damage all enemies in large radius
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		
		var dist = global_position.distance_to(enemy.global_position)
		if dist < 150:
			if enemy.has_method("_on_hurt_box_hurt"):
				var angle = global_position.direction_to(enemy.global_position)
				enemy._on_hurt_box_hurt(int(damage * 0.75), angle, knockback_amount)

func find_next_target(from_pos: Vector2) -> Node2D:
	var closest_enemy: Node2D = null
	var closest_dist: float = chain_range
	
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
	
	# Dramatic fade out
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)
