extends Node2D

## Enhanced Enemy Spawner with Elite/Boss support and Wave system

@export var spawns: Array[Spawn_info] = []

# Elite spawn configuration
@export var elite_spawn_interval: float = 60.0  # Seconds between elite spawns
@export var mini_boss_times: Array[int] = [300, 600]  # 5 min, 10 min
@export var final_boss_time: int = 900  # 15 min

@onready var player = get_tree().get_first_node_in_group("player")

@export var time = 0

# Elite tracking
var time_since_last_elite: float = 0.0
var elite_count: int = 0
var boss_count: int = 0
var final_boss_spawned := false
var final_boss_killed := false

# Preload enemy scenes for elite spawning
var enemy_scenes = {
	"kobold_weak": preload("res://Enemy/enemy_kobold_weak.tscn"),
	"kobold_strong": preload("res://Enemy/enemy_kobold_strong.tscn"),
	"cyclops": preload("res://Enemy/enemy_cyclops.tscn"),
	"juggernaut": preload("res://Enemy/enemy_juggernaut.tscn"),
	"super": preload("res://Enemy/enemy_super.tscn"),
	# New enemies
	"slime": preload("res://Enemy/enemy_slime.tscn"),
	"ghost": preload("res://Enemy/enemy_ghost.tscn"),
	"bomber": preload("res://Enemy/enemy_bomber.tscn")
}

# Treasure chest
var treasure_chest = preload("res://Objects/treasure_chest.tscn")

signal changetime(time)

func _ready():
	connect("changetime", Callable(player, "change_time"))
	
	# Connect to GameManager treasure spawn signal
	if GameManager:
		GameManager.treasure_spawned.connect(_on_treasure_spawn_triggered)

func _on_timer_timeout():
	time += 1
	time_since_last_elite += 1
	
	# Regular enemy spawning
	var enemy_spawns = spawns
	for i in enemy_spawns:
		if time >= i.time_start and time <= i.time_end:
			if i.spawn_delay_counter < i.enemy_spawn_delay:
				i.spawn_delay_counter += 1
			else:
				i.spawn_delay_counter = 0
				var new_enemy = i.enemy
				var counter = 0
				while counter < i.enemy_num:
					var enemy_spawn = new_enemy.instantiate()
					enemy_spawn.global_position = get_random_position()
					add_child(enemy_spawn)
					counter += 1
	
	# Spawn Slimes in groups (every 3 seconds, from start)
	if time % 3 == 0 and time >= 0:
		var slime_count = 2 + int(time / 60)  # More slimes over time
		slime_count = min(slime_count, 6)  # Cap at 6
		for i in range(slime_count):
			spawn_enemy_type("slime")
	
	# Spawn Ghosts (every 8 seconds, after 90 seconds)
	if time % 8 == 0 and time >= 90:
		spawn_enemy_type("ghost")
		if time >= 180:
			spawn_enemy_type("ghost")  # 2 ghosts after 3 min
	
	# Spawn Bombers (every 15 seconds, after 150 seconds)
	if time % 15 == 0 and time >= 150:
		spawn_enemy_type("bomber")
	
	# Elite spawn check
	if time_since_last_elite >= elite_spawn_interval:
		spawn_elite()
		time_since_last_elite = 0.0
	
	# Mini-boss spawn check (at 5 min and 10 min)
	if time in mini_boss_times:
		spawn_mini_boss()
	
	# Final boss spawn at 15 min
	if time == final_boss_time and not final_boss_spawned:
		spawn_final_boss()
	
	emit_signal("changetime", time)

func spawn_enemy_type(enemy_type: String):
	if enemy_scenes.has(enemy_type):
		var enemy = enemy_scenes[enemy_type].instantiate()
		enemy.global_position = get_random_position()
		add_child(enemy)

func spawn_elite():
	# Pick a random enemy type based on current time
	var available_types = ["kobold_strong"]
	if time > 60:
		available_types.append("cyclops")
	if time > 120:
		available_types.append("juggernaut")
	
	var enemy_type = available_types.pick_random()
	if enemy_scenes.has(enemy_type):
		var elite = enemy_scenes[enemy_type].instantiate()
		elite.global_position = get_random_position()
		
		# Apply elite modifiers directly (since we may not have elite script attached)
		elite.hp *= 3
		elite.experience *= 3
		elite.enemy_damage = int(elite.enemy_damage * 1.5)
		elite.enemy_type = "elite_" + enemy_type
		
		# Visual indicator - make it glow
		elite.modulate = Color(1.0, 0.85, 0.3, 1.0)  # Gold tint
		elite.scale *= 1.3
		
		add_child(elite)
		elite_count += 1
		
		# Elite drops treasure on death
		elite.tree_exiting.connect(func(): spawn_treasure_at(elite.global_position, 1))

func spawn_mini_boss():
	# Mini-boss: stronger than elite, weaker than final boss
	var boss_type = "juggernaut" if time >= 600 else "cyclops"
	
	if enemy_scenes.has(boss_type):
		var boss = enemy_scenes[boss_type].instantiate()
		boss.global_position = get_random_position()
		
		# Mini-boss modifiers (5x stats)
		boss.hp *= 5
		boss.experience *= 5
		boss.enemy_damage = int(boss.enemy_damage * 1.5)
		boss.enemy_type = "miniboss_" + boss_type
		
		# Visual - purple glow
		boss.modulate = Color(0.8, 0.3, 1.0, 1.0)
		boss.scale *= 1.5
		
		add_child(boss)
		boss_count += 1
		
		# Emit boss spawned signal
		if GameManager:
			GameManager.boss_spawned.emit("mini_" + boss_type)
		
		# Mini-boss drops treasure on death
		boss.tree_exiting.connect(func(): spawn_treasure_at(boss.global_position, 2))

func spawn_final_boss():
	final_boss_spawned = true
	
	# Final boss: the "super" enemy with massive stats
	if enemy_scenes.has("super"):
		var boss = enemy_scenes["super"].instantiate()
		boss.global_position = get_random_position()
		
		# Final boss modifiers (15x stats)
		boss.hp *= 15
		boss.experience *= 15
		boss.enemy_damage *= 3
		boss.enemy_type = "final_boss"
		
		# Visual - red glow and massive
		boss.modulate = Color(1.0, 0.2, 0.2, 1.0)
		boss.scale *= 2.5
		
		add_child(boss)
		boss_count += 1
		
		# Screen shake for dramatic entrance
		var camera = get_viewport().get_camera_2d()
		if camera and camera.has_method("shake"):
			camera.big_shake()
		
		# Emit boss spawned signal
		if GameManager:
			GameManager.boss_spawned.emit("final_boss")
		
		# Final boss death = VICTORY!
		boss.tree_exiting.connect(_on_final_boss_killed)

func _on_final_boss_killed():
	final_boss_killed = true
	# Trigger victory through player death function (time >= 900 will show "Victory")
	if player and player.has_method("death"):
		player.time = 900  # Ensure victory screen shows
		player.death()

func spawn_treasure_at(pos: Vector2, tier: int = 1):
	var chest = treasure_chest.instantiate()
	chest.global_position = pos
	# Tier 1 (elite) = 8 gold, Tier 2 = 16, Tier 3 (boss) = 24
	chest.gold_amount = 8 * tier
	get_parent().call_deferred("add_child", chest)

func _on_treasure_spawn_triggered(position: Vector2):
	# Called by GameManager when kill threshold reached
	spawn_treasure_at(position, 1)

func get_random_position():
	var vpr = get_viewport_rect().size * randf_range(1.1, 1.4)
	var top_left = Vector2(player.global_position.x - vpr.x/2, player.global_position.y - vpr.y/2)
	var top_right = Vector2(player.global_position.x + vpr.x/2, player.global_position.y - vpr.y/2)
	var bottom_left = Vector2(player.global_position.x - vpr.x/2, player.global_position.y + vpr.y/2)
	var bottom_right = Vector2(player.global_position.x + vpr.x/2, player.global_position.y + vpr.y/2)
	var pos_side = ["up", "down", "right", "left"].pick_random()
	var spawn_pos1 = Vector2.ZERO
	var spawn_pos2 = Vector2.ZERO
	
	match pos_side:
		"up":
			spawn_pos1 = top_left
			spawn_pos2 = top_right
		"down":
			spawn_pos1 = bottom_left
			spawn_pos2 = bottom_right
		"right":
			spawn_pos1 = top_right
			spawn_pos2 = bottom_right
		"left":
			spawn_pos1 = top_left
			spawn_pos2 = bottom_left
	
	var x_spawn = randf_range(spawn_pos1.x, spawn_pos2.x)
	var y_spawn = randf_range(spawn_pos1.y, spawn_pos2.y)
	return Vector2(x_spawn, y_spawn)
