extends Node2D

## POI Spawner - Manages spawning of Points of Interest during gameplay

# Spawn configuration
@export var first_spawn_time: float = 45.0  ## Seconds before first POI spawns
@export var spawn_interval_min: float = 45.0  ## Minimum seconds between spawns
@export var spawn_interval_max: float = 75.0  ## Maximum seconds between spawns
@export var max_active_pois: int = 2  ## Maximum POIs active at once
@export var spawn_distance_min: float = 150.0  ## Minimum distance from player
@export var spawn_distance_max: float = 300.0  ## Maximum distance from player

# POI scenes
var poi_scenes = {
	"challenge_shrine": preload("res://Objects/POI/challenge_shrine.tscn")
}

# State
var time_elapsed: float = 0.0
var time_until_next_spawn: float = 0.0
var active_pois: Array[Node] = []
var spawns_enabled := true

# References
@onready var player: Node2D = null

signal poi_spawned(poi: Node)
signal poi_removed(poi: Node)

func _ready():
	add_to_group("poi_spawner")
	
	# Get player reference
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	
	# Set first spawn time
	time_until_next_spawn = first_spawn_time
	
	print("[POI Spawner] Initialized. First POI in %.1fs" % first_spawn_time)

func _process(delta: float):
	if not spawns_enabled or not player:
		return
	
	time_elapsed += delta
	time_until_next_spawn -= delta
	
	# Clean up null references
	active_pois = active_pois.filter(func(poi): return is_instance_valid(poi))
	
	# Check if we should spawn a new POI
	if time_until_next_spawn <= 0 and active_pois.size() < max_active_pois:
		spawn_poi()
		# Set next spawn time
		time_until_next_spawn = randf_range(spawn_interval_min, spawn_interval_max)

func spawn_poi():
	"""Spawn a random POI at a valid position."""
	if not player:
		return
	
	# For MVP, only spawn challenge shrines
	var poi_type = "challenge_shrine"
	
	if not poi_scenes.has(poi_type):
		push_warning("[POI Spawner] Unknown POI type: %s" % poi_type)
		return
	
	var poi = poi_scenes[poi_type].instantiate()
	poi.global_position = get_spawn_position()
	
	# Connect signals
	poi.poi_completed.connect(_on_poi_completed)
	poi.poi_expired.connect(_on_poi_expired)
	
	# Add to scene
	get_parent().add_child(poi)
	active_pois.append(poi)
	
	emit_signal("poi_spawned", poi)
	print("[POI Spawner] Spawned %s at %s. Active POIs: %d" % [poi_type, poi.global_position, active_pois.size()])

func get_spawn_position() -> Vector2:
	"""Get a valid spawn position around the player."""
	if not player:
		return Vector2.ZERO
	
	# Try multiple times to find a good position
	for _attempt in range(10):
		var angle = randf() * TAU
		var distance = randf_range(spawn_distance_min, spawn_distance_max)
		var pos = player.global_position + Vector2(cos(angle), sin(angle)) * distance
		
		# Could add additional checks here (not too close to enemies, etc.)
		return pos
	
	# Fallback: just spawn at configured distance
	return player.global_position + Vector2.RIGHT.rotated(randf() * TAU) * spawn_distance_max

func _on_poi_completed(poi: Node, _success: bool):
	"""Called when a POI is completed (success or failure)."""
	active_pois.erase(poi)
	emit_signal("poi_removed", poi)
	print("[POI Spawner] POI completed. Active POIs: %d" % active_pois.size())

func _on_poi_expired(poi: Node):
	"""Called when a POI expires without being activated."""
	active_pois.erase(poi)
	emit_signal("poi_removed", poi)
	print("[POI Spawner] POI expired. Active POIs: %d" % active_pois.size())

# Public methods for external control
func enable_spawning():
	spawns_enabled = true

func disable_spawning():
	spawns_enabled = false

func clear_all_pois():
	"""Remove all active POIs."""
	for poi in active_pois:
		if is_instance_valid(poi):
			poi.queue_free()
	active_pois.clear()
