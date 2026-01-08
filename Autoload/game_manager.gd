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

# Evolution system signals
signal essence_collected(amount: int)
signal evolution_available(weapon_id: String)
signal evolution_applied(weapon_id: String, evolution_id: String)

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
	"essence": 0,  # Rare currency for powerful evolutions
	"time": 0,
	"weapons": [],
	"passives": [],
	"evolved_weapons": [],  # Track which weapons have been evolved
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
		"essence": 0,
		"time": 0,
		"weapons": [],
		"passives": [],
		"evolved_weapons": []
	}
	run_stats = {
		"kills": 0,
		"time": 0,
		"gold_collected": 0,
		"essence_collected": 0,
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

func spend_gold(amount: int) -> bool:
	if current_run.gold >= amount:
		current_run.gold -= amount
		return true
	return false

# --- Essence Management ---
func add_essence(amount: int = 1):
	current_run.essence += amount
	run_stats.essence_collected += amount
	emit_signal("essence_collected", amount)

func spend_essence(amount: int) -> bool:
	if current_run.essence >= amount:
		current_run.essence -= amount
		return true
	return false

func get_essence() -> int:
	return current_run.essence

func get_gold() -> int:
	return current_run.gold

# --- Evolution Management ---
func try_evolve_weapon(weapon_id: String, evolution: EvolutionData) -> bool:
	"""Attempt to evolve a weapon. Returns true if successful."""
	var weapon_level = get_weapon_level(weapon_id)
	var passive_level = 0
	if evolution.requires_passive_id != "":
		passive_level = get_passive_level(evolution.requires_passive_id)
	
	# Check requirements
	if not evolution.can_evolve(weapon_level, passive_level, current_run.gold, current_run.essence):
		return false
	
	# Spend resources
	if evolution.cost_gold > 0 and not spend_gold(evolution.cost_gold):
		return false
	if evolution.cost_essence > 0 and not spend_essence(evolution.cost_essence):
		# Refund gold if essence fails
		add_gold(evolution.cost_gold)
		return false
	
	# Mark weapon as evolved
	if not weapon_id in current_run.evolved_weapons:
		current_run.evolved_weapons.append(weapon_id)
	
	emit_signal("evolution_applied", weapon_id, evolution.id)
	return true

func is_weapon_evolved(weapon_id: String) -> bool:
	return weapon_id in current_run.evolved_weapons

func check_evolution_available(weapon_id: String):
	"""Check if a weapon is ready for evolution and emit signal."""
	var weapon_level = get_weapon_level(weapon_id)
	if weapon_level >= 4 and not is_weapon_evolved(weapon_id):
		emit_signal("evolution_available", weapon_id)

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

# --- Character Unlock System ---
const CHARACTER_UNLOCKS = {
	"mage": {
		"name": "Mage",
		"description": "Starting character",
		"unlock_condition": "default",
		"sprite": "res://Textures/Player/player_sprite.png",
		"starting_weapon": "icespear1",
		"hp_bonus": 0,
		"speed_bonus": 0,
		"special": "+20% Spell Size"
	},
	"knight": {
		"name": "Knight",
		"description": "Tanky close-range fighter",
		"unlock_condition": "reach_level_15",
		"sprite": "res://Textures/Player/knight_sprite.png",
		"starting_weapon": "holycross1",
		"hp_bonus": 30,
		"speed_bonus": -10,
		"special": "+2 Armor"
	},
	"rogue": {
		"name": "Rogue",
		"description": "Fast and deadly",
		"unlock_condition": "kill_100_enemies",
		"sprite": "res://Textures/Player/rogue_sprite.png",
		"starting_weapon": "lightning1",
		"hp_bonus": -20,
		"speed_bonus": 30,
		"special": "-10% Cooldowns"
	},
	"necromancer": {
		"name": "Necromancer",
		"description": "Master of dark magic",
		"unlock_condition": "win_run",
		"sprite": "res://Textures/Player/player_sprite.png",
		"starting_weapon": "magicmissile1",
		"hp_bonus": -10,
		"speed_bonus": 0,
		"special": "+1 Additional Attack"
	},
	"berserker": {
		"name": "Berserker",
		"description": "More damage at low HP",
		"unlock_condition": "kill_500_enemies_total",
		"sprite": "res://Textures/Player/player_sprite.png",
		"starting_weapon": "tornado1",
		"hp_bonus": 50,
		"speed_bonus": 20,
		"special": "Rage Mode at 25% HP"
	}
}

# Lifetime stats for unlocks
var lifetime_stats = {
	"total_kills": 0,
	"total_runs": 0,
	"total_wins": 0,
	"highest_level": 0,
	"evolutions_unlocked": 0
}

func check_unlock_conditions():
	# Check each character unlock condition
	for char_id in CHARACTER_UNLOCKS:
		if char_id in persistent_data.unlocked_characters:
			continue
		
		var condition = CHARACTER_UNLOCKS[char_id].unlock_condition
		var unlocked = false
		
		match condition:
			"default":
				unlocked = true
			"reach_level_15":
				unlocked = current_run.level >= 15 or lifetime_stats.highest_level >= 15
			"kill_100_enemies":
				unlocked = run_stats.kills >= 100
			"win_run":
				unlocked = lifetime_stats.total_wins >= 1
			"kill_500_enemies_total":
				unlocked = lifetime_stats.total_kills >= 500
		
		if unlocked and not char_id in persistent_data.unlocked_characters:
			unlock_character(char_id)

func unlock_character(char_id: String):
	if not char_id in persistent_data.unlocked_characters:
		persistent_data.unlocked_characters.append(char_id)
		print("[UNLOCK] Character unlocked: %s" % CHARACTER_UNLOCKS[char_id].name)
		save_persistent_data()

func is_character_unlocked(char_id: String) -> bool:
	return char_id in persistent_data.unlocked_characters

func get_unlocked_characters() -> Array:
	return persistent_data.unlocked_characters

func get_character_data(char_id: String) -> Dictionary:
	if CHARACTER_UNLOCKS.has(char_id):
		return CHARACTER_UNLOCKS[char_id]
	return {}

func update_lifetime_stats():
	lifetime_stats.total_kills += run_stats.kills
	lifetime_stats.total_runs += 1
	if current_run.level > lifetime_stats.highest_level:
		lifetime_stats.highest_level = current_run.level
	
	# Check unlocks at end of run
	check_unlock_conditions()
