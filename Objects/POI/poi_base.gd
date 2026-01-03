extends Area2D
class_name POIBase

## Base class for all Points of Interest (POI) in the game
## POIs are optional objectives that spawn during runs and offer rewards

signal poi_activated(poi: POIBase)
signal poi_completed(poi: POIBase, success: bool)
signal poi_expired(poi: POIBase)
signal quest_progress_updated(current: int, target: int, quest_type: String)
signal quest_time_updated(time_remaining: float, is_in_zone: bool)

# Configuration
@export var expiration_time: float = 60.0  ## Seconds before POI expires if not engaged
@export var poi_name: String = "Unknown POI"
@export var glow_color: Color = Color(0.3, 0.8, 1.0, 1.0)  ## Cyan glow by default

# Announcement display properties
@export var poi_description: String = "A mysterious point of interest awaits..."
@export var reward_description: String = "Unknown reward"

## Returns the quest objective text. Override in child classes.
func get_quest_description() -> String:
	return "Complete the challenge!"

## Returns the reward type for display purposes. Override in child classes.
func get_reward_type_name() -> String:
	return reward_description

# State
var is_active := false  ## True when player has activated this POI
var is_expired := false
var is_completed := false
var player_ref: Node2D = null

# Nodes (override in child scenes)
@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else null
@onready var glow_sprite: Sprite2D = $GlowSprite2D if has_node("GlowSprite2D") else null
@onready var collision: CollisionShape2D = $CollisionShape2D if has_node("CollisionShape2D") else null
@onready var expiration_timer: Timer = $ExpirationTimer if has_node("ExpirationTimer") else null

func _ready():
	add_to_group("poi")
	
	# Get player reference
	player_ref = get_tree().get_first_node_in_group("player")
	
	# Connect body entered signal for activation
	body_entered.connect(_on_body_entered)
	
	# Setup expiration timer
	if expiration_timer:
		expiration_timer.wait_time = expiration_time
		expiration_timer.one_shot = true
		expiration_timer.timeout.connect(_on_expiration_timeout)
		expiration_timer.start()
	
	# Spawn animation
	_play_spawn_animation()
	
	# Start glow effect
	_start_glow_effect()

func _process(_delta: float):
	if not is_active and not is_expired and not is_completed:
		_update_glow_effect()

func _play_spawn_animation():
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _start_glow_effect():
	if glow_sprite:
		glow_sprite.modulate = glow_color
		glow_sprite.modulate.a = 0.5

func _update_glow_effect():
	# Pulsing glow effect
	if glow_sprite:
		var pulse = (sin(Time.get_ticks_msec() * 0.005) + 1.0) * 0.25 + 0.3
		glow_sprite.modulate.a = pulse

func _on_body_entered(body: Node2D):
	if body.is_in_group("player") and not is_active and not is_expired and not is_completed:
		activate()

func activate():
	"""Called when player enters the POI area. Override in child classes."""
	if is_active or is_expired or is_completed:
		return
	
	is_active = true
	
	# Stop expiration timer since player engaged
	if expiration_timer:
		expiration_timer.stop()
	
	# Visual feedback
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color(1.5, 1.5, 1.5, 1.0), 0.1)
	tween.tween_property(self, "modulate", Color.WHITE, 0.1)
	
	# Screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(5.0, 0.3)
	
	emit_signal("poi_activated", self)

func complete(success: bool):
	"""Called when the POI challenge is finished. Override reward logic in child classes."""
	if is_completed:
		return
	
	is_completed = true
	is_active = false
	
	emit_signal("poi_completed", self, success)
	
	if success:
		_play_success_effect()
		_grant_reward()
	else:
		_play_failure_effect()
	
	# Despawn after effect
	await get_tree().create_timer(1.0).timeout
	queue_free()

func _on_expiration_timeout():
	"""Called when POI expires before player engages."""
	if is_active or is_completed:
		return
	
	is_expired = true
	emit_signal("poi_expired", self)
	
	# Fade out animation
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(queue_free)

func _play_success_effect():
	# Golden burst effect
	modulate = Color(1.5, 1.3, 0.5, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.5, 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.5)
	
	# Particles
	if has_method("spawn_reward_particles"):
		spawn_reward_particles()

func _play_failure_effect():
	# Red flash and shrink
	modulate = Color(1.0, 0.3, 0.3, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ZERO, 0.3)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.3)

func _grant_reward():
	"""Override in child classes to give specific rewards."""
	pass

func spawn_reward_particles():
	"""Spawn celebratory particles on success."""
	for i in range(12):
		var sparkle = Sprite2D.new()
		sparkle.modulate = Color(1, 0.9, 0.3, 1)
		sparkle.global_position = global_position
		get_parent().add_child(sparkle)
		
		var angle = i * (TAU / 12)
		var target_pos = global_position + Vector2(cos(angle), sin(angle)) * 50
		
		var tween = sparkle.create_tween().set_parallel(true)
		tween.tween_property(sparkle, "global_position", target_pos, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(sparkle, "modulate:a", 0.0, 0.6)
		tween.chain().tween_callback(sparkle.queue_free)
