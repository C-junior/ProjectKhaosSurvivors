extends POIBase
class_name ChallengeShrineArea

## Challenge Shrine POI - Activates a timed combat challenge
## Player must complete the objective within the time limit to earn rewards

enum ChallengeType {
	KILL_RUSH,      ## Kill X enemies within time limit
	SURVIVAL,       ## Stay in zone for X seconds
}

# Challenge configuration
@export var challenge_type: ChallengeType = ChallengeType.KILL_RUSH
@export var kill_target: int = 25  ## Enemies to kill for KILL_RUSH
@export var survival_time: float = 12.0  ## Seconds to survive for SURVIVAL
@export var challenge_duration: float = 25.0  ## Max time to complete challenge
@export var zone_radius: float = 80.0  ## Radius for SURVIVAL zone

# Challenge state
var kills_during_challenge: int = 0
var survival_progress: float = 0.0
var challenge_active := false
var challenge_timer: float = 0.0

# Reward configuration
@export var reward_type: String = "levelup"  ## "levelup", "treasure", or "evolution"
@export var treasure_tier: int = 2  ## For treasure rewards

# Node references
@onready var challenge_label: Label = $ChallengeLabel if has_node("ChallengeLabel") else null
@onready var zone_indicator: Sprite2D = $ZoneIndicator if has_node("ZoneIndicator") else null
@onready var activation_sound: AudioStreamPlayer = $ActivationSound if has_node("ActivationSound") else null
@onready var completion_sound: AudioStreamPlayer = $CompletionSound if has_node("CompletionSound") else null
@onready var progress_bar: ProgressBar = $ProgressBar if has_node("ProgressBar") else null

func _ready():
	super._ready()
	poi_name = "Challenge Shrine"
	glow_color = Color(0.2, 0.6, 1.0, 1.0)  # Blue glow
	
	# Randomize challenge type
	challenge_type = ChallengeType.values().pick_random()
	
	# Hide challenge UI initially
	if challenge_label:
		challenge_label.visible = false
	if zone_indicator:
		zone_indicator.visible = false
	if progress_bar:
		progress_bar.visible = false

func _process(delta: float):
	super._process(delta)
	
	if challenge_active:
		_update_challenge(delta)

func _update_challenge(delta: float):
	challenge_timer -= delta
	
	match challenge_type:
		ChallengeType.KILL_RUSH:
			_update_kill_rush_ui()
		ChallengeType.SURVIVAL:
			_update_survival(delta)
	
	# Check timeout
	if challenge_timer <= 0:
		complete(false)

func _update_kill_rush_ui():
	if challenge_label:
		challenge_label.text = "KILL: %d/%d\nTime: %.1fs" % [kills_during_challenge, kill_target, challenge_timer]
	if progress_bar:
		progress_bar.value = float(kills_during_challenge) / float(kill_target) * 100.0

func _update_survival(delta: float):
	# Check if player is in zone
	if player_ref and global_position.distance_to(player_ref.global_position) <= zone_radius:
		survival_progress += delta
		if zone_indicator:
			zone_indicator.modulate = Color(0.3, 1.0, 0.3, 0.4)  # Green when in zone
	else:
		if zone_indicator:
			zone_indicator.modulate = Color(1.0, 0.3, 0.3, 0.4)  # Red when out of zone
	
	if challenge_label:
		challenge_label.text = "STAY IN ZONE\n%.1fs / %.1fs" % [survival_progress, survival_time]
	if progress_bar:
		progress_bar.value = survival_progress / survival_time * 100.0
	
	# Check win condition
	if survival_progress >= survival_time:
		complete(true)

func activate():
	super.activate()
	
	challenge_active = true
	challenge_timer = challenge_duration
	kills_during_challenge = 0
	survival_progress = 0.0
	
	# Play activation sound
	if activation_sound:
		activation_sound.play()
	
	# Show challenge UI
	if challenge_label:
		challenge_label.visible = true
	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = 0
	
	# Show zone for survival challenge
	if challenge_type == ChallengeType.SURVIVAL and zone_indicator:
		zone_indicator.visible = true
		zone_indicator.scale = Vector2.ONE * (zone_radius / 16.0)  # Assuming 16px base sprite
	
	# Connect to enemy death signals
	_connect_enemy_signals()
	
	# Visual feedback - screen shake and flash
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(6.0, 0.4)
	
	# Glow intensify
	if glow_sprite:
		var tween = create_tween()
		tween.tween_property(glow_sprite, "modulate:a", 0.8, 0.2)

func _connect_enemy_signals():
	# Connect to enemy death events through the tree
	get_tree().node_added.connect(_on_node_added)
	
	# Also track existing enemies
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if not enemy.tree_exiting.is_connected(_on_enemy_killed):
			enemy.tree_exiting.connect(_on_enemy_killed.bind(enemy))

func _on_node_added(node: Node):
	if challenge_active and node.is_in_group("enemy"):
		if not node.tree_exiting.is_connected(_on_enemy_killed):
			node.tree_exiting.connect(_on_enemy_killed.bind(node))

func _on_enemy_killed(_enemy: Node):
	if not challenge_active or challenge_type != ChallengeType.KILL_RUSH:
		return
	
	kills_during_challenge += 1
	
	# Check win condition
	if kills_during_challenge >= kill_target:
		complete(true)

func complete(success: bool):
	challenge_active = false
	
	# Disconnect signals
	if get_tree().node_added.is_connected(_on_node_added):
		get_tree().node_added.disconnect(_on_node_added)
	
	# Play sound
	if success and completion_sound:
		completion_sound.play()
	
	# Hide UI
	if challenge_label:
		challenge_label.visible = false
	if zone_indicator:
		zone_indicator.visible = false
	if progress_bar:
		progress_bar.visible = false
	
	super.complete(success)

func _grant_reward():
	match reward_type:
		"levelup":
			# Grant a level-up to the player
			if player_ref and player_ref.has_method("levelup"):
				player_ref.levelup()
		"treasure":
			# Spawn a treasure chest
			var treasure_scene = preload("res://Objects/treasure_chest.tscn")
			var chest = treasure_scene.instantiate()
			chest.global_position = global_position
			chest.gold_amount = 15 * treasure_tier  # 30 gold for tier 2
			get_parent().call_deferred("add_child", chest)
		"evolution":
			# Add progress toward an evolution (simplified: just grant XP)
			if player_ref and player_ref.has_method("calculate_experience"):
				player_ref.calculate_experience(50)

func _play_success_effect():
	super._play_success_effect()
	spawn_reward_particles()
