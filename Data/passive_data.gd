class_name PassiveData extends Resource

## Data-driven passive item definition

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export_file("*.png") var icon_path: String = ""

# What stat does this passive modify?
@export_enum("armor", "movement_speed", "spell_size", "spell_cooldown", 
	"additional_attacks", "pickup_radius", "xp_multiplier", "luck", "regen", "max_hp") var stat_type: String = "armor"

# Per-level effect values
@export var levels: Array[PassiveLevel] = []

# For evolution system - which weapon does this passive evolve?
@export var evolves_weapon: String = ""

func get_level_data(level: int) -> PassiveLevel:
	if level <= 0 or level > levels.size():
		return null
	return levels[level - 1]

func is_max_level(level: int) -> bool:
	return level >= levels.size()

func get_max_level() -> int:
	return levels.size()
