class_name EvolutionData extends Resource

## Data-driven evolution definition for weapons
## Create .tres resource files for each evolution path

@export var id: String = ""
@export var display_name: String = ""
@export var description: String = ""
@export_multiline var effect_details: String = ""

# Icon for evolution selection UI
@export_file("*.png") var icon_path: String = ""

# Evolution costs
@export var cost_gold: int = 400
@export var cost_essence: int = 0

# Requirements
@export var requires_weapon_id: String = ""  # Base weapon that evolves
@export var requires_weapon_level: int = 4
@export var requires_passive_id: String = ""  # Optional passive requirement
@export var requires_passive_level: int = 0

# The evolved weapon scene
@export var evolved_scene: PackedScene

# Tags for synergy display
@export var tags: Array[String] = []

# Which evolution path this is (A or B for dual-path system)
@export_enum("A", "B") var path: String = "A"

func can_evolve(weapon_level: int, passive_level: int, player_gold: int, player_essence: int) -> bool:
	# Check weapon level requirement
	if weapon_level < requires_weapon_level:
		return false
	
	# Check passive requirement (if any)
	if requires_passive_id != "" and passive_level < requires_passive_level:
		return false
	
	# Check resource costs
	if player_gold < cost_gold:
		return false
	if player_essence < cost_essence:
		return false
	
	return true

func get_cost_string() -> String:
	var parts: Array[String] = []
	if cost_gold > 0:
		parts.append("%d Gold" % cost_gold)
	if cost_essence > 0:
		parts.append("%d Essence" % cost_essence)
	return " + ".join(parts) if parts.size() > 0 else "Free"

func get_requirements_string() -> String:
	var parts: Array[String] = []
	parts.append("Weapon Lv%d" % requires_weapon_level)
	if requires_passive_id != "":
		parts.append("%s Lv%d" % [requires_passive_id.capitalize(), requires_passive_level])
	return " + ".join(parts)
