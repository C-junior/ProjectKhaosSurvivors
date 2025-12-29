class_name WeaponData extends Resource

## Data-driven weapon definition
## Create .tres resource files for each weapon

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export_file("*.png") var icon_path: String = ""
@export var scene: PackedScene

# Per-level stats
@export var levels: Array[WeaponLevel] = []

# Evolution system
@export var evolution_into: String = ""  # ID of evolved weapon
@export var evolution_requires: String = ""  # Required passive item ID

# Weapon behavior type
@export_enum("Projectile", "Orbit", "Area", "Beam") var weapon_type: String = "Projectile"

# Base timing
@export var base_cooldown: float = 1.5
@export var base_projectile_count: int = 1

func get_level_data(level: int) -> WeaponLevel:
	if level <= 0 or level > levels.size():
		return null
	return levels[level - 1]

func is_max_level(level: int) -> bool:
	return level >= levels.size()

func get_max_level() -> int:
	return levels.size()
