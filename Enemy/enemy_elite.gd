extends "res://Enemy/enemy.gd"

## Elite Enemy - Stronger version with glowing effect and guaranteed loot

@export var elite_tier: int = 1  # 1 = normal elite, 2 = mini-boss, 3 = boss

# Elite modifiers
var base_hp_multiplier := 3.0
var base_damage_multiplier := 1.5
var base_xp_multiplier := 3.0
var base_size_multiplier := 1.3

@onready var glow_effect = $GlowEffect
@onready var elite_indicator = $EliteIndicator

var treasure_chest = preload("res://Objects/treasure_chest.tscn")

func _ready():
	super._ready()
	apply_elite_modifiers()
	setup_visual_effects()

func apply_elite_modifiers():
	var tier_bonus = elite_tier * 0.5
	
	hp = int(hp * (base_hp_multiplier + tier_bonus))
	enemy_damage = int(enemy_damage * (base_damage_multiplier + tier_bonus * 0.25))
	experience = int(experience * (base_xp_multiplier + tier_bonus))
	
	# Make elites slightly bigger
	var size = base_size_multiplier + (elite_tier - 1) * 0.2
	scale = Vector2.ONE * size

func setup_visual_effects():
	# Add colored aura based on tier
	var tint_color: Color
	match elite_tier:
		1:
			tint_color = Color(1.0, 0.8, 0.2, 0.8)  # Gold
		2:
			tint_color = Color(0.6, 0.3, 1.0, 0.8)  # Purple
		3:
			tint_color = Color(1.0, 0.2, 0.2, 0.8)  # Red (boss)
	
	if glow_effect:
		glow_effect.modulate = tint_color
		glow_effect.visible = true
	
	# Pulsing animation
	var tween = create_tween().set_loops()
	tween.tween_property(self, "modulate", tint_color * 1.2, 0.5)
	tween.tween_property(self, "modulate", Color.WHITE, 0.5)

func death():
	# Elite enemies always drop treasure
	spawn_treasure()
	
	# Chance to drop essence based on tier
	# Tier 1: 2%, Tier 2: 10%, Tier 3 (boss): 100%
	var essence_chance = 0.02 + (elite_tier - 1) * 0.08
	if elite_tier >= 3:
		essence_chance = 1.0
	
	if randf() < essence_chance:
		GameManager.add_essence(1)
		# Visual feedback - could spawn essence particle here
		print("[Elite] Dropped 1 Essence!")
	
	# Notify GameManager
	GameManager.register_kill("elite_" + str(elite_tier), global_position, experience)
	
	super.death()

func spawn_treasure():
	var chest = treasure_chest.instantiate()
	chest.global_position = global_position
	
	# Scale gold reward based on tier
	chest.gold_amount = 10 * elite_tier
	
	get_parent().call_deferred("add_child", chest)
