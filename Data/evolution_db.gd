extends Node

## Evolution Database - Centralized evolution definitions
## Contains all weapon evolutions with dual-path options

# Evolution data organized by base weapon ID
const EVOLUTIONS = {
	# ===== FIRE RING EVOLUTIONS =====
	"firering": {
		"path_a": {
			"id": "inferno_orbit",
			"display_name": "Inferno Orbit",
			"description": "+2 orbs that apply Burn stacks",
			"effect_details": "Orbital rings multiply and leave burning trails. Enemies touched take fire damage over time.",
			"cost_gold": 400,
			"cost_essence": 0,
			"requires_passive_id": "speed",
			"requires_passive_level": 3,
			"evolved_scene": "res://Player/Attack/inferno_aura.tscn",
			"tags": ["fire", "orbit", "dot"]
		},
		"path_b": {
			"id": "pyre_field",
			"display_name": "Pyre Field",
			"description": "Orbs create fire zones on collision",
			"effect_details": "When rings hit enemies, they leave behind fiery ground that damages enemies standing in it.",
			"cost_gold": 300,
			"cost_essence": 1,
			"requires_passive_id": "",
			"requires_passive_level": 0,
			"evolved_scene": "res://Player/Attack/pyre_field.tscn",
			"tags": ["fire", "zone", "control"]
		}
	},
	
	# ===== LIGHTNING EVOLUTIONS =====
	"lightning": {
		"path_a": {
			"id": "chain_overload",
			"display_name": "Chain Overload",
			"description": "+4 chain jumps, chaos unleashed",
			"effect_details": "Lightning bounces to 10 enemies total with reduced damage falloff per jump.",
			"cost_gold": 400,
			"cost_essence": 0,
			"requires_passive_id": "crown",
			"requires_passive_level": 3,
			"evolved_scene": "res://Player/Attack/storm_caller.tscn",
			"tags": ["chain", "arcane", "multi"]
		},
		"path_b": {
			"id": "tesla_anchor",
			"display_name": "Tesla Anchor",
			"description": "Place a turret that auto-zaps",
			"effect_details": "When standing still, deploy an electric turret that automatically chains lightning to nearby enemies.",
			"cost_gold": 350,
			"cost_essence": 1,
			"requires_passive_id": "",
			"requires_passive_level": 0,
			"evolved_scene": "res://Player/Attack/tesla_anchor.tscn",
			"tags": ["turret", "arcane", "static"]
		}
	},
	
	# ===== MAGIC MISSILE EVOLUTIONS =====
	"magicmissile": {
		"path_a": {
			"id": "homing_swarm",
			"display_name": "Homing Swarm",
			"description": "+3 missiles, slower but with crit",
			"effect_details": "Fire 7 homing missiles that move slower but have 15% bonus critical chance.",
			"cost_gold": 400,
			"cost_essence": 0,
			"requires_passive_id": "luck",
			"requires_passive_level": 3,
			"evolved_scene": "res://Player/Attack/arcane_barrage.tscn",
			"tags": ["projectile", "homing", "crit"]
		},
		"path_b": {
			"id": "arcane_spears",
			"display_name": "Arcane Spears",
			"description": "Piercing line projectiles",
			"effect_details": "Missiles become piercing arcane spears that pass through all enemies in a line.",
			"cost_gold": 350,
			"cost_essence": 1,
			"requires_passive_id": "",
			"requires_passive_level": 0,
			"evolved_scene": "res://Player/Attack/arcane_spears.tscn",
			"tags": ["projectile", "pierce", "line"]
		}
	},
	
	# ===== ICE SPEAR EVOLUTIONS =====
	"icespear": {
		"path_a": {
			"id": "frost_nova",
			"display_name": "Frost Nova",
			"description": "AoE explosion on hit",
			"effect_details": "Ice spears explode on impact, dealing area damage and slowing nearby enemies.",
			"cost_gold": 400,
			"cost_essence": 0,
			"requires_passive_id": "tome",
			"requires_passive_level": 4,
			"evolved_scene": "res://Player/Attack/frost_nova.tscn",
			"tags": ["ice", "aoe", "control"]
		},
		"path_b": {
			"id": "glacial_barrage",
			"display_name": "Glacial Barrage",
			"description": "Rapid-fire ice shards",
			"effect_details": "Fire a barrage of smaller ice projectiles that slow enemies on hit.",
			"cost_gold": 300,
			"cost_essence": 1,
			"requires_passive_id": "",
			"requires_passive_level": 0,
			"evolved_scene": "res://Player/Attack/glacial_barrage.tscn",
			"tags": ["ice", "projectile", "rapid"]
		}
	},
	
	# ===== TORNADO EVOLUTIONS =====
	"tornado": {
		"path_a": {
			"id": "maelstrom",
			"display_name": "Maelstrom",
			"description": "Larger, pulls enemies in",
			"effect_details": "Tornados become massive maelstroms that pull enemies toward their center.",
			"cost_gold": 400,
			"cost_essence": 0,
			"requires_passive_id": "scroll",
			"requires_passive_level": 4,
			"evolved_scene": "res://Player/Attack/maelstrom.tscn",
			"tags": ["wind", "aoe", "control"]
		},
		"path_b": {
			"id": "cyclone_army",
			"display_name": "Cyclone Army",
			"description": "Summon 3 smaller tornados",
			"effect_details": "Spawn 3 smaller but faster tornados that spread out and cover more area.",
			"cost_gold": 350,
			"cost_essence": 1,
			"requires_passive_id": "",
			"requires_passive_level": 0,
			"evolved_scene": "res://Player/Attack/cyclone_army.tscn",
			"tags": ["wind", "multi", "speed"]
		}
	},
	
	# ===== JAVELIN EVOLUTIONS =====
	"javelin": {
		"path_a": {
			"id": "spear_barrage",
			"display_name": "Spear Barrage",
			"description": "Rapid-fire javelins",
			"effect_details": "The javelin attacks much faster, firing a constant stream of projectiles.",
			"cost_gold": 400,
			"cost_essence": 0,
			"requires_passive_id": "ring",
			"requires_passive_level": 4,
			"evolved_scene": "res://Player/Attack/spear_barrage.tscn",
			"tags": ["orbit", "rapid", "damage"]
		},
		"path_b": {
			"id": "guardian_spear",
			"display_name": "Guardian Spear",
			"description": "Orbiting shield that blocks",
			"effect_details": "The javelin orbits closer and blocks enemy projectiles while dealing damage.",
			"cost_gold": 300,
			"cost_essence": 1,
			"requires_passive_id": "",
			"requires_passive_level": 0,
			"evolved_scene": "res://Player/Attack/guardian_spear.tscn",
			"tags": ["orbit", "defense", "melee"]
		}
	},
	
	# ===== HOLY CROSS EVOLUTIONS =====
	"holycross": {
		"path_a": {
			"id": "divine_wrath",
			"display_name": "Divine Wrath",
			"description": "Explodes at max range",
			"effect_details": "The boomerang explodes when it reaches maximum distance, dealing massive area damage.",
			"cost_gold": 400,
			"cost_essence": 0,
			"requires_passive_id": "armor",
			"requires_passive_level": 4,
			"evolved_scene": "res://Player/Attack/divine_wrath.tscn",
			"tags": ["return", "aoe", "burst"]
		},
		"path_b": {
			"id": "judgment_blade",
			"display_name": "Judgment Blade",
			"description": "Splits into 4 on return",
			"effect_details": "When returning, the cross splits into 4 smaller projectiles that spread outward.",
			"cost_gold": 350,
			"cost_essence": 1,
			"requires_passive_id": "",
			"requires_passive_level": 0,
			"evolved_scene": "res://Player/Attack/judgment_blade.tscn",
			"tags": ["return", "split", "multi"]
		}
	}
}

# Helper functions
func get_evolutions_for_weapon(weapon_id: String) -> Dictionary:
	if EVOLUTIONS.has(weapon_id):
		return EVOLUTIONS[weapon_id]
	return {}

func get_evolution_path(weapon_id: String, path: String) -> Dictionary:
	if EVOLUTIONS.has(weapon_id) and EVOLUTIONS[weapon_id].has(path):
		return EVOLUTIONS[weapon_id][path]
	return {}

func can_afford_evolution(evolution: Dictionary, gold: int, essence: int) -> bool:
	return gold >= evolution.get("cost_gold", 0) and essence >= evolution.get("cost_essence", 0)

func get_available_evolutions(weapon_id: String, weapon_level: int, passives: Dictionary, gold: int, essence: int) -> Array:
	"""Returns list of evolutions the player can currently afford and meets requirements for."""
	var available = []
	
	if weapon_level < 4:
		return available
	
	var weapon_evolutions = get_evolutions_for_weapon(weapon_id)
	for path in ["path_a", "path_b"]:
		if weapon_evolutions.has(path):
			var evo = weapon_evolutions[path]
			var passive_met = true
			
			if evo.get("requires_passive_id", "") != "":
				var req_passive = evo.requires_passive_id
				var req_level = evo.get("requires_passive_level", 0)
				passive_met = passives.get(req_passive, 0) >= req_level
			
			if passive_met:
				var can_afford = can_afford_evolution(evo, gold, essence)
				available.append({
					"path": path,
					"data": evo,
					"can_afford": can_afford
				})
	
	return available
