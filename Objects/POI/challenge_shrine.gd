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
	
	# Set visual description
	poi_description = "An ancient mystical shrine pulses with arcane energy, beckoning warriors to prove their worth..."
	
	# Randomize challenge type
	challenge_type = ChallengeType.values().pick_random()
	
	# Set reward description based on reward_type
	_update_reward_description()
	
	# Hide challenge UI initially
	if challenge_label:
		challenge_label.visible = false
	if zone_indicator:
		zone_indicator.visible = false
	if progress_bar:
		progress_bar.visible = false

func _update_reward_description():
	match reward_type:
		"levelup":
			reward_description = "⬆️ Instant Level Up!"
		"treasure":
			reward_description = "💰 Treasure Chest (%d Gold)" % (15 * treasure_tier)
		"evolution":
			reward_description = "✨ +50 Bonus XP"
		_:
			reward_description = "🎁 Mystery Reward"

func get_quest_description() -> String:
	match challenge_type:
		ChallengeType.KILL_RUSH:
			return "⚔️ Kill %d enemies near the shrine!" % kill_target
		ChallengeType.SURVIVAL:
			return "🛡️ Survive %.0f seconds inside the zone!" % survival_time
		_:
			return "Complete the challenge!"

func get_reward_type_name() -> String:
	return reward_description

func _process(delta: float):
	super._process(delta)
	
	if challenge_active:
		_update_challenge(delta)

func _update_challenge(delta: float):
	challenge_timer -= delta
	
	match challenge_type:
		ChallengeType.KILL_RUSH:
			_update_kill_rush_ui()
			# Emit timer for quest tracker
			emit_signal("quest_time_updated", challenge_timer, true)
		ChallengeType.SURVIVAL:
			_update_survival(delta)
	
	# Check timeout
	if challenge_timer <= 0:
		print("[Challenge Shrine] TIMEOUT! Challenge failed!")
		complete(false)

func _update_kill_rush_ui():
	if challenge_label:
		challenge_label.text = "KILL: %d/%d\nTime: %.1fs" % [kills_during_challenge, kill_target, challenge_timer]
	if progress_bar:
		progress_bar.value = float(kills_during_challenge) / float(kill_target) * 100.0
	
	# Emit progress for HUD tracker
	emit_signal("quest_progress_updated", kills_during_challenge, kill_target, "kill")

func _update_survival(delta: float):
	# Check if player is in zone
	var is_in_zone = player_ref and global_position.distance_to(player_ref.global_position) <= zone_radius
	
	if is_in_zone:
		survival_progress += delta
		if zone_indicator:
			zone_indicator.modulate = Color(0.3, 1.0, 0.3, 0.5)  # Green when in zone
	else:
		# Timer pauses when player leaves zone (doesn't reset or increase)
		if zone_indicator:
			zone_indicator.modulate = Color(1.0, 0.3, 0.3, 0.5)  # Red when out of zone
	
	var time_remaining = survival_time - survival_progress
	
	if challenge_label:
		if is_in_zone:
			challenge_label.text = "STAY IN ZONE\n%.1fs remaining" % time_remaining
		else:
			challenge_label.text = "RETURN TO ZONE!\n%.1fs remaining" % time_remaining
	if progress_bar:
		progress_bar.value = survival_progress / survival_time * 100.0
	
	# Emit time update for HUD tracker
	emit_signal("quest_time_updated", time_remaining, is_in_zone)
	
	# Check win condition
	if survival_progress >= survival_time:
		complete(true)

func activate():
	print("[Challenge Shrine] ACTIVATE called! Challenge type: ", challenge_type)
	super.activate()
	
	challenge_active = true
	challenge_timer = challenge_duration
	kills_during_challenge = 0
	survival_progress = 0.0
	
	print("[Challenge Shrine] Challenge started! Timer: %.1fs, Target: %d kills / %.1fs survival" % [challenge_timer, kill_target, survival_time])
	
	# Play activation sound
	if activation_sound:
		activation_sound.play()
	
	# Show challenge UI
	if challenge_label:
		challenge_label.visible = true
	if progress_bar:
		progress_bar.visible = true
		progress_bar.value = 0
	
	# Show zone indicator for both challenge types
	if zone_indicator:
		zone_indicator.visible = true
		if challenge_type == ChallengeType.SURVIVAL:
			zone_indicator.scale = Vector2.ONE * (zone_radius / 16.0)  # Smaller survival zone
			zone_indicator.modulate = Color(0.3, 1.0, 0.3, 0.4)  # Green
		else:
			# Kill rush uses larger zone to show kill counting area
			zone_indicator.scale = Vector2.ONE * (zone_radius * 2.5 / 16.0)
			zone_indicator.modulate = Color(0.5, 0.5, 1.0, 0.3)  # Blue/purple
	
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
	# Connect to GameManager's enemy_killed signal (reliable kill tracking)
	if GameManager and not GameManager.enemy_killed.is_connected(_on_enemy_killed):
		GameManager.enemy_killed.connect(_on_enemy_killed)
	print("[Challenge Shrine] Connected to GameManager.enemy_killed signal")

func _disconnect_enemy_signals():
	# Disconnect from GameManager when challenge ends
	if GameManager and GameManager.enemy_killed.is_connected(_on_enemy_killed):
		GameManager.enemy_killed.disconnect(_on_enemy_killed)

func _on_enemy_killed(_enemy_type: String, position: Vector2):
	if not challenge_active or challenge_type != ChallengeType.KILL_RUSH:
		return
	
	# Only count kills near the shrine (within larger radius)
	var kill_radius = zone_radius * 2.5  # 200 units for default 80 radius
	if global_position.distance_to(position) <= kill_radius:
		kills_during_challenge += 1
		print("[Challenge Shrine] Kill counted: %d/%d" % [kills_during_challenge, kill_target])
		
		# Check win condition
		if kills_during_challenge >= kill_target:
			complete(true)

func complete(success: bool):
	challenge_active = false
	
	# Disconnect GameManager kill signal
	_disconnect_enemy_signals()
	
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
