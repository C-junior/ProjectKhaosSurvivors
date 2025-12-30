extends Node


const ICON_PATH = "res://Textures/Items/Upgrades/"
const WEAPON_PATH = "res://Textures/Items/Weapons/"
const UPGRADES = {
	"icespear1": {
		"icon": WEAPON_PATH + "ice_spear.png",
		"displayname": "Ice Spear",
		"details": "A spear of ice is thrown at a random enemy",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"icespear2": {
		"icon": WEAPON_PATH + "ice_spear.png",
		"displayname": "Ice Spear",
		"details": "An addition Ice Spear is thrown",
		"level": "Level: 2",
		"prerequisite": ["icespear1"],
		"type": "weapon"
	},
	"icespear3": {
		"icon": WEAPON_PATH + "ice_spear.png",
		"displayname": "Ice Spear",
		"details": "Ice Spears now pass through another enemy and do + 3 damage",
		"level": "Level: 3",
		"prerequisite": ["icespear2"],
		"type": "weapon"
	},
	"icespear4": {
		"icon": WEAPON_PATH + "ice_spear.png",
		"displayname": "Ice Spear",
		"details": "An additional 2 Ice Spears are thrown",
		"level": "Level: 4",
		"prerequisite": ["icespear3"],
		"type": "weapon"
	},
	"javelin1": {
		"icon": WEAPON_PATH + "javelin_3_new_attack.png",
		"displayname": "Javelin",
		"details": "A magical javelin will follow you attacking enemies in a straight line",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"javelin2": {
		"icon": WEAPON_PATH + "javelin_3_new_attack.png",
		"displayname": "Javelin",
		"details": "The javelin will now attack an additional enemy per attack",
		"level": "Level: 2",
		"prerequisite": ["javelin1"],
		"type": "weapon"
	},
	"javelin3": {
		"icon": WEAPON_PATH + "javelin_3_new_attack.png",
		"displayname": "Javelin",
		"details": "The javelin will attack another additional enemy per attack",
		"level": "Level: 3",
		"prerequisite": ["javelin2"],
		"type": "weapon"
	},
	"javelin4": {
		"icon": WEAPON_PATH + "javelin_3_new_attack.png",
		"displayname": "Javelin",
		"details": "The javelin now does + 5 damage per attack and causes 20% additional knockback",
		"level": "Level: 4",
		"prerequisite": ["javelin3"],
		"type": "weapon"
	},
	"tornado1": {
		"icon": WEAPON_PATH + "tornado.png",
		"displayname": "Tornado",
		"details": "A tornado is created and random heads somewhere in the players direction",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"tornado2": {
		"icon": WEAPON_PATH + "tornado.png",
		"displayname": "Tornado",
		"details": "An additional Tornado is created",
		"level": "Level: 2",
		"prerequisite": ["tornado1"],
		"type": "weapon"
	},
	"tornado3": {
		"icon": WEAPON_PATH + "tornado.png",
		"displayname": "Tornado",
		"details": "The Tornado cooldown is reduced by 0.5 seconds",
		"level": "Level: 3",
		"prerequisite": ["tornado2"],
		"type": "weapon"
	},
	"tornado4": {
		"icon": WEAPON_PATH + "tornado.png",
		"displayname": "Tornado",
		"details": "An additional tornado is created and the knockback is increased by 25%",
		"level": "Level: 4",
		"prerequisite": ["tornado3"],
		"type": "weapon"
	},
	# NEW WEAPONS
	"holycross1": {
		"icon": WEAPON_PATH + "ice_spear.png",
		"displayname": "Holy Cross",
		"details": "A boomerang that travels outward and returns, hitting enemies both ways",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"holycross2": {
		"icon": WEAPON_PATH + "ice_spear.png",
		"displayname": "Holy Cross",
		"details": "Increased damage and travel distance",
		"level": "Level: 2",
		"prerequisite": ["holycross1"],
		"type": "weapon"
	},
	"holycross3": {
		"icon": WEAPON_PATH + "ice_spear.png",
		"displayname": "Holy Cross",
		"details": "Increased damage, speed, and size",
		"level": "Level: 3",
		"prerequisite": ["holycross2"],
		"type": "weapon"
	},
	"holycross4": {
		"icon": WEAPON_PATH + "ice_spear.png",
		"displayname": "Holy Cross",
		"details": "Maximum damage and range",
		"level": "Level: 4",
		"prerequisite": ["holycross3"],
		"type": "weapon"
	},
	"firering1": {
		"icon": WEAPON_PATH + "tornado.png",
		"displayname": "Fire Ring",
		"details": "A ring of fire orbits around you, damaging nearby enemies",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"firering2": {
		"icon": WEAPON_PATH + "tornado.png",
		"displayname": "Fire Ring",
		"details": "Increased damage and orbit radius",
		"level": "Level: 2",
		"prerequisite": ["firering1"],
		"type": "weapon"
	},
	"firering3": {
		"icon": WEAPON_PATH + "tornado.png",
		"displayname": "Fire Ring",
		"details": "Faster orbit speed and more damage",
		"level": "Level: 3",
		"prerequisite": ["firering2"],
		"type": "weapon"
	},
	"firering4": {
		"icon": WEAPON_PATH + "tornado.png",
		"displayname": "Fire Ring",
		"details": "Maximum damage and area coverage",
		"level": "Level: 4",
		"prerequisite": ["firering3"],
		"type": "weapon"
	},
	"lightning1": {
		"icon": WEAPON_PATH + "javelin_3_new_attack.png",
		"displayname": "Lightning",
		"details": "A bolt of lightning that chains between 2 enemies",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "weapon"
	},
	"lightning2": {
		"icon": WEAPON_PATH + "javelin_3_new_attack.png",
		"displayname": "Lightning",
		"details": "Chains to 3 enemies with more damage",
		"level": "Level: 2",
		"prerequisite": ["lightning1"],
		"type": "weapon"
	},
	"lightning3": {
		"icon": WEAPON_PATH + "javelin_3_new_attack.png",
		"displayname": "Lightning",
		"details": "Chains to 4 enemies with increased range",
		"level": "Level: 3",
		"prerequisite": ["lightning2"],
		"type": "weapon"
	},
	"lightning4": {
		"icon": WEAPON_PATH + "javelin_3_new_attack.png",
		"displayname": "Lightning",
		"details": "Chains to 5 enemies with maximum damage",
		"level": "Level: 4",
		"prerequisite": ["lightning3"],
		"type": "weapon"
	},
	"armor1": {
		"icon": ICON_PATH + "helmet_1.png",
		"displayname": "Armor",
		"details": "Reduces Damage By 1 point",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"armor2": {
		"icon": ICON_PATH + "helmet_1.png",
		"displayname": "Armor",
		"details": "Reduces Damage By an additional 1 point",
		"level": "Level: 2",
		"prerequisite": ["armor1"],
		"type": "upgrade"
	},
	"armor3": {
		"icon": ICON_PATH + "helmet_1.png",
		"displayname": "Armor",
		"details": "Reduces Damage By an additional 1 point",
		"level": "Level: 3",
		"prerequisite": ["armor2"],
		"type": "upgrade"
	},
	"armor4": {
		"icon": ICON_PATH + "helmet_1.png",
		"displayname": "Armor",
		"details": "Reduces Damage By an additional 1 point",
		"level": "Level: 4",
		"prerequisite": ["armor3"],
		"type": "upgrade"
	},
	"speed1": {
		"icon": ICON_PATH + "boots_4_green.png",
		"displayname": "Speed",
		"details": "Movement Speed Increased by 50% of base speed",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"speed2": {
		"icon": ICON_PATH + "boots_4_green.png",
		"displayname": "Speed",
		"details": "Movement Speed Increased by an additional 50% of base speed",
		"level": "Level: 2",
		"prerequisite": ["speed1"],
		"type": "upgrade"
	},
	"speed3": {
		"icon": ICON_PATH + "boots_4_green.png",
		"displayname": "Speed",
		"details": "Movement Speed Increased by an additional 50% of base speed",
		"level": "Level: 3",
		"prerequisite": ["speed2"],
		"type": "upgrade"
	},
	"speed4": {
		"icon": ICON_PATH + "boots_4_green.png",
		"displayname": "Speed",
		"details": "Movement Speed Increased an additional 50% of base speed",
		"level": "Level: 4",
		"prerequisite": ["speed3"],
		"type": "upgrade"
	},
	"tome1": {
		"icon": ICON_PATH + "thick_new.png",
		"displayname": "Tome",
		"details": "Increases the size of spells an additional 10% of their base size",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"tome2": {
		"icon": ICON_PATH + "thick_new.png",
		"displayname": "Tome",
		"details": "Increases the size of spells an additional 10% of their base size",
		"level": "Level: 2",
		"prerequisite": ["tome1"],
		"type": "upgrade"
	},
	"tome3": {
		"icon": ICON_PATH + "thick_new.png",
		"displayname": "Tome",
		"details": "Increases the size of spells an additional 10% of their base size",
		"level": "Level: 3",
		"prerequisite": ["tome2"],
		"type": "upgrade"
	},
	"tome4": {
		"icon": ICON_PATH + "thick_new.png",
		"displayname": "Tome",
		"details": "Increases the size of spells an additional 10% of their base size",
		"level": "Level: 4",
		"prerequisite": ["tome3"],
		"type": "upgrade"
	},
	"scroll1": {
		"icon": ICON_PATH + "scroll_old.png",
		"displayname": "Scroll",
		"details": "Decreases of the cooldown of spells by an additional 5% of their base time",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"scroll2": {
		"icon": ICON_PATH + "scroll_old.png",
		"displayname": "Scroll",
		"details": "Decreases of the cooldown of spells by an additional 5% of their base time",
		"level": "Level: 2",
		"prerequisite": ["scroll1"],
		"type": "upgrade"
	},
	"scroll3": {
		"icon": ICON_PATH + "scroll_old.png",
		"displayname": "Scroll",
		"details": "Decreases of the cooldown of spells by an additional 5% of their base time",
		"level": "Level: 3",
		"prerequisite": ["scroll2"],
		"type": "upgrade"
	},
	"scroll4": {
		"icon": ICON_PATH + "scroll_old.png",
		"displayname": "Scroll",
		"details": "Decreases of the cooldown of spells by an additional 5% of their base time",
		"level": "Level: 4",
		"prerequisite": ["scroll3"],
		"type": "upgrade"
	},
	"ring1": {
		"icon": ICON_PATH + "urand_mage.png",
		"displayname": "Ring",
		"details": "Your spells now spawn 1 more additional attack",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"ring2": {
		"icon": ICON_PATH + "urand_mage.png",
		"displayname": "Ring",
		"details": "Your spells now spawn an additional attack",
		"level": "Level: 2",
		"prerequisite": ["ring1"],
		"type": "upgrade"
	},
	"ring3": {
		"icon": ICON_PATH + "urand_mage.png",
		"displayname": "Ring",
		"details": "Your spells now spawn an additional attack",
		"level": "Level: 3",
		"prerequisite": ["ring2"],
		"type": "upgrade"
	},
	"ring4": {
		"icon": ICON_PATH + "urand_mage.png",
		"displayname": "Ring",
		"details": "Your spells now spawn an additional attack",
		"level": "Level: 4",
		"prerequisite": ["ring3"],
		"type": "upgrade"
	},
	# NEW PASSIVES
	"magnet1": {
		"icon": ICON_PATH + "urand_mage.png",
		"displayname": "Magnet",
		"details": "Increases pickup radius by 30%",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"magnet2": {
		"icon": ICON_PATH + "urand_mage.png",
		"displayname": "Magnet",
		"details": "Increases pickup radius by an additional 30%",
		"level": "Level: 2",
		"prerequisite": ["magnet1"],
		"type": "upgrade"
	},
	"magnet3": {
		"icon": ICON_PATH + "urand_mage.png",
		"displayname": "Magnet",
		"details": "Increases pickup radius by an additional 30%",
		"level": "Level: 3",
		"prerequisite": ["magnet2"],
		"type": "upgrade"
	},
	"magnet4": {
		"icon": ICON_PATH + "urand_mage.png",
		"displayname": "Magnet",
		"details": "Increases pickup radius by an additional 30%",
		"level": "Level: 4",
		"prerequisite": ["magnet3"],
		"type": "upgrade"
	},
	"luck1": {
		"icon": ICON_PATH + "scroll_old.png",
		"displayname": "Luck",
		"details": "Increases gold and rare drop chance by 10%",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"luck2": {
		"icon": ICON_PATH + "scroll_old.png",
		"displayname": "Luck",
		"details": "Increases gold and rare drop chance by an additional 10%",
		"level": "Level: 2",
		"prerequisite": ["luck1"],
		"type": "upgrade"
	},
	"luck3": {
		"icon": ICON_PATH + "scroll_old.png",
		"displayname": "Luck",
		"details": "Increases gold and rare drop chance by an additional 10%",
		"level": "Level: 3",
		"prerequisite": ["luck2"],
		"type": "upgrade"
	},
	"luck4": {
		"icon": ICON_PATH + "scroll_old.png",
		"displayname": "Luck",
		"details": "Increases gold and rare drop chance by an additional 10%",
		"level": "Level: 4",
		"prerequisite": ["luck3"],
		"type": "upgrade"
	},
	"crown1": {
		"icon": ICON_PATH + "helmet_1.png",
		"displayname": "Crown",
		"details": "Increases XP gain by 10%",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"crown2": {
		"icon": ICON_PATH + "helmet_1.png",
		"displayname": "Crown",
		"details": "Increases XP gain by an additional 10%",
		"level": "Level: 2",
		"prerequisite": ["crown1"],
		"type": "upgrade"
	},
	"crown3": {
		"icon": ICON_PATH + "helmet_1.png",
		"displayname": "Crown",
		"details": "Increases XP gain by an additional 10%",
		"level": "Level: 3",
		"prerequisite": ["crown2"],
		"type": "upgrade"
	},
	"crown4": {
		"icon": ICON_PATH + "helmet_1.png",
		"displayname": "Crown",
		"details": "Increases XP gain by an additional 10%",
		"level": "Level: 4",
		"prerequisite": ["crown3"],
		"type": "upgrade"
	},
	"duplicator1": {
		"icon": ICON_PATH + "thick_new.png",
		"displayname": "Duplicator",
		"details": "All weapons fire 1 extra projectile",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"duplicator2": {
		"icon": ICON_PATH + "thick_new.png",
		"displayname": "Duplicator",
		"details": "All weapons fire 1 extra projectile",
		"level": "Level: 2",
		"prerequisite": ["duplicator1"],
		"type": "upgrade"
	},
	"regen1": {
		"icon": ICON_PATH + "chunk.png",
		"displayname": "Regeneration",
		"details": "Recover 0.5 HP per second",
		"level": "Level: 1",
		"prerequisite": [],
		"type": "upgrade"
	},
	"regen2": {
		"icon": ICON_PATH + "chunk.png",
		"displayname": "Regeneration",
		"details": "Recover an additional 0.5 HP per second",
		"level": "Level: 2",
		"prerequisite": ["regen1"],
		"type": "upgrade"
	},
	"regen3": {
		"icon": ICON_PATH + "chunk.png",
		"displayname": "Regeneration",
		"details": "Recover an additional 0.5 HP per second",
		"level": "Level: 3",
		"prerequisite": ["regen2"],
		"type": "upgrade"
	},
	"regen4": {
		"icon": ICON_PATH + "chunk.png",
		"displayname": "Regeneration",
		"details": "Recover an additional 0.5 HP per second",
		"level": "Level: 4",
		"prerequisite": ["regen3"],
		"type": "upgrade"
	},
	"food": {
		"icon": ICON_PATH + "chunk.png",
		"displayname": "Food",
		"details": "Heals you for 20 health",
		"level": "N/A",
		"prerequisite": [],
		"type": "item"
	}
}

# Weapon Evolution mappings
const EVOLUTIONS = {
	"icespear": {
		"requires": "tome4",
		"evolves_into": "frost_nova",
		"displayname": "Frost Nova"
	},
	"tornado": {
		"requires": "scroll4",
		"evolves_into": "maelstrom",
		"displayname": "Maelstrom"
	},
	"javelin": {
		"requires": "ring4",
		"evolves_into": "spear_barrage",
		"displayname": "Spear Barrage"
	},
	"holycross": {
		"requires": "armor4",
		"evolves_into": "divine_wrath",
		"displayname": "Divine Wrath"
	},
	"firering": {
		"requires": "speed4",
		"evolves_into": "inferno_aura",
		"displayname": "Inferno Aura"
	},
	"lightning": {
		"requires": "crown4",
		"evolves_into": "storm_caller",
		"displayname": "Storm Caller"
	}
}

func can_evolve(weapon_base: String, collected_upgrades: Array) -> bool:
	if not EVOLUTIONS.has(weapon_base):
		return false
	
	var evolution = EVOLUTIONS[weapon_base]
	var weapon_maxed = (weapon_base + "4") in collected_upgrades
	var passive_met = evolution.requires in collected_upgrades
	
	return weapon_maxed and passive_met

func get_evolution(weapon_base: String) -> Dictionary:
	if EVOLUTIONS.has(weapon_base):
		return EVOLUTIONS[weapon_base]
	return {}
