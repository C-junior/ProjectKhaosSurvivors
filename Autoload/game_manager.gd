extends Node

## GameManager - Centralized game state and signals
## Autoload singleton for managing game-wide data

# Signals for game events
signal enemy_killed(enemy_type: String, position: Vector2)
signal level_up(new_level: int)
signal treasure_spawned(position: Vector2)
signal weapon_evolved(from_weapon: String, to_weapon: String)
signal gold_collected(amount: int)
signal boss_spawned(boss_type: String)
signal player_died()

# Run Statistics
var run_stats = {
	"kills": 0,
	"time": 0,
	"gold_collected": 0,
	"damage_dealt": 0,
	"damage_taken": 0
}

# Persistent Data (saved between runs)
var persistent_data = {
	"total_gold": 0,
	"unlocked_characters": ["mage"],
	"unlocked_weapons": ["icespear"],
	"permanent_upgrades": {
		"max_hp": 0,
		"movement_speed": 0,
		"pickup_radius": 0,
		"xp_gain": 0
	},
	"achievements": []
}

# Current Run Data
var current_run = {
	"character": "mage",
	"level": 1,
	"experience": 0,
	"gold": 0,
	"time": 0,
	"weapons": [],
	"passives": [],
	"sprite": "res://Textures/Player/player_sprite.png"
}

# Player Stats (base + modifiers)
var player_stats = {
	"hp": 80,
	"max_hp": 80,
	"movement_speed": 40.0,
	"armor": 0,
	"pickup_radius": 1.0,
	"xp_multiplier": 1.0,
	"spell_size": 0.0,
	"spell_cooldown": 0.0,
	"additional_attacks": 0,
	"luck": 0.0,
	"regen": 0.0
}

# Treasure/Chest spawn thresholds
var kills_until_treasure := 30
var kills_since_last_treasure := 0

# Save file path
const SAVE_PATH = "user://save_data.json"

func _ready():
	load_persistent_data()

func _process(delta):
	# Handle regeneration
	if player_stats.regen > 0:
		player_stats.hp = min(player_stats.hp + player_stats.regen * delta, player_stats.max_hp)

# --- Run Management ---
func start_new_run(character: String = "mage"):
	current_run = {
		"character": character,
		"level": 1,
		"experience": 0,
		"gold": 0,
		"time": 0,
		"weapons": [],
		"passives": []
	}
	run_stats = {
		"kills": 0,
		"time": 0,
		"gold_collected": 0,
		"damage_dealt": 0,
		"damage_taken": 0
	}
	reset_player_stats()
	apply_permanent_upgrades()
	kills_since_last_treasure = 0

func end_run():
	# Add collected gold to persistent
	persistent_data.total_gold += current_run.gold
	save_persistent_data()

func reset_player_stats():
	player_stats = {
		"hp": 80,
		"max_hp": 80,
		"movement_speed": 40.0,
		"armor": 0,
		"pickup_radius": 1.0,
		"xp_multiplier": 1.0,
		"spell_size": 0.0,
		"spell_cooldown": 0.0,
		"additional_attacks": 0,
		"luck": 0.0,
		"regen": 0.0
	}

func apply_permanent_upgrades():
	player_stats.max_hp += persistent_data.permanent_upgrades.max_hp * 10
	player_stats.hp = player_stats.max_hp
	player_stats.movement_speed += persistent_data.permanent_upgrades.movement_speed * 5
	player_stats.pickup_radius += persistent_data.permanent_upgrades.pickup_radius * 0.2
	player_stats.xp_multiplier += persistent_data.permanent_upgrades.xp_gain * 0.1

# --- Enemy/Kill Management ---
func register_kill(enemy_type: String, position: Vector2, xp_value: int = 1):
	run_stats.kills += 1
	kills_since_last_treasure += 1
	emit_signal("enemy_killed", enemy_type, position)
	
	# Check treasure spawn
	if kills_since_last_treasure >= kills_until_treasure:
		kills_since_last_treasure = 0
		emit_signal("treasure_spawned", position)

# --- Experience & Leveling ---
func add_experience(amount: int):
	var modified_amount = int(amount * player_stats.xp_multiplier)
	current_run.experience += modified_amount
	
	var exp_needed = calculate_exp_needed()
	while current_run.experience >= exp_needed:
		current_run.experience -= exp_needed
		current_run.level += 1
		emit_signal("level_up", current_run.level)
		exp_needed = calculate_exp_needed()

func calculate_exp_needed() -> int:
	var level = current_run.level
	if level < 20:
		return level * 5
	elif level < 40:
		return 95 + (level - 19) * 8
	else:
		return 255 + (level - 39) * 12

# --- Weapon Management ---
func add_weapon(weapon_id: String):
	if not weapon_id in current_run.weapons:
		current_run.weapons.append(weapon_id)

func get_weapon_level(weapon_id: String) -> int:
	# Get highest level of this weapon type collected
	var base_id = weapon_id.rstrip("0123456789")
	var highest = 0
	for w in current_run.weapons:
		if w.begins_with(base_id):
			var level_str = w.substr(base_id.length())
			if level_str.is_valid_int():
				highest = max(highest, level_str.to_int())
	return highest

func can_evolve_weapon(weapon_id: String, required_passive: String) -> bool:
	var weapon_level = get_weapon_level(weapon_id)
	var passive_level = get_passive_level(required_passive)
	return weapon_level >= 4 and passive_level >= 4

# --- Passive Management ---
func add_passive(passive_id: String):
	if not passive_id in current_run.passives:
		current_run.passives.append(passive_id)

func get_passive_level(passive_id: String) -> int:
	var base_id = passive_id.rstrip("0123456789")
	var highest = 0
	for p in current_run.passives:
		if p.begins_with(base_id):
			var level_str = p.substr(base_id.length())
			if level_str.is_valid_int():
				highest = max(highest, level_str.to_int())
	return highest

# --- Gold Management ---
func add_gold(amount: int):
	var modified_amount = int(amount * (1.0 + player_stats.luck * 0.1))
	current_run.gold += modified_amount
	run_stats.gold_collected += modified_amount
	emit_signal("gold_collected", modified_amount)

# --- Stat Modifications ---
func modify_stat(stat_name: String, value: float):
	if player_stats.has(stat_name):
		player_stats[stat_name] += value

func get_stat(stat_name: String) -> float:
	if player_stats.has(stat_name):
		return player_stats[stat_name]
	return 0.0

# --- Save/Load ---
func save_persistent_data():
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(persistent_data))
		file.close()

func load_persistent_data():
	if FileAccess.file_exists(SAVE_PATH):
		var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
		if file:
			var json = JSON.new()
			var result = json.parse(file.get_as_text())
			if result == OK:
				var data = json.get_data()
				if data is Dictionary:
					# Merge loaded data with defaults
					for key in data.keys():
						persistent_data[key] = data[key]
			file.close()

# --- Utility ---
func get_random_upgrade_from_pool(exclude: Array = []) -> String:
	# Will be used by level-up UI to get random upgrades
	var all_upgrades = UpgradeDb.UPGRADES.keys()
	var valid = []
	for upgrade in all_upgrades:
		if upgrade in exclude:
			continue
		if upgrade in current_run.weapons or upgrade in current_run.passives:
			continue
		# Check prerequisites
		var prereqs = UpgradeDb.UPGRADES[upgrade].get("prerequisite", [])
		var prereq_met = true
		for prereq in prereqs:
			if not prereq in current_run.weapons and not prereq in current_run.passives:
				prereq_met = false
				break
		if prereq_met:
			valid.append(upgrade)
	
	if valid.size() > 0:
		return valid.pick_random()
	return ""
