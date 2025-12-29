extends Control

## Meta-Progression Shop
## Players spend gold earned from runs on permanent upgrades

@onready var gold_label = $GoldLabel
@onready var upgrade_container = $UpgradeContainer

const PERMANENT_UPGRADES = {
	"max_hp": {
		"name": "Max HP",
		"description": "+10 Max HP per level",
		"icon": "res://Textures/Items/Upgrades/helmet_1.png",
		"base_cost": 100,
		"cost_scale": 1.5,
		"max_level": 10,
		"stat": "max_hp",
		"value_per_level": 10
	},
	"movement_speed": {
		"name": "Movement Speed",
		"description": "+5% movement speed per level",
		"icon": "res://Textures/Items/Upgrades/boots_4_green.png",
		"base_cost": 150,
		"cost_scale": 1.6,
		"max_level": 5,
		"stat": "movement_speed",
		"value_per_level": 5
	},
	"pickup_radius": {
		"name": "Pickup Radius",
		"description": "+20% pickup radius per level",
		"icon": "res://Textures/Items/Upgrades/urand_mage.png",
		"base_cost": 200,
		"cost_scale": 1.5,
		"max_level": 5,
		"stat": "pickup_radius",
		"value_per_level": 0.2
	},
	"xp_gain": {
		"name": "XP Gain",
		"description": "+10% XP gain per level",
		"icon": "res://Textures/Items/Upgrades/thick_new.png",
		"base_cost": 250,
		"cost_scale": 1.7,
		"max_level": 5,
		"stat": "xp_gain",
		"value_per_level": 0.1
	},
	"starting_armor": {
		"name": "Starting Armor",
		"description": "+1 armor at run start",
		"icon": "res://Textures/Items/Upgrades/helmet_1.png",
		"base_cost": 300,
		"cost_scale": 2.0,
		"max_level": 3,
		"stat": "armor",
		"value_per_level": 1
	},
	"luck": {
		"name": "Luck",
		"description": "+5% better drops per level",
		"icon": "res://Textures/Items/Upgrades/scroll_old.png",
		"base_cost": 200,
		"cost_scale": 1.5,
		"max_level": 5,
		"stat": "luck",
		"value_per_level": 0.05
	}
}

func _ready():
	update_gold_display()
	create_upgrade_buttons()

func update_gold_display():
	if GameManager:
		gold_label.text = "Gold: %d" % GameManager.persistent_data.total_gold

func create_upgrade_buttons():
	# Clear existing
	for child in upgrade_container.get_children():
		child.queue_free()
	
	for upgrade_id in PERMANENT_UPGRADES:
		var upgrade = PERMANENT_UPGRADES[upgrade_id]
		var current_level = get_upgrade_level(upgrade_id)
		var is_maxed = current_level >= upgrade.max_level
		
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(200, 80)
		
		var vbox = VBoxContainer.new()
		
		# Name and level
		var name_label = Label.new()
		name_label.text = "%s (Lv %d/%d)" % [upgrade.name, current_level, upgrade.max_level]
		vbox.add_child(name_label)
		
		# Description
		var desc_label = Label.new()
		desc_label.text = upgrade.description
		desc_label.add_theme_font_size_override("font_size", 10)
		vbox.add_child(desc_label)
		
		# Buy button
		var cost = calculate_cost(upgrade_id)
		var buy_button = Button.new()
		if is_maxed:
			buy_button.text = "MAXED"
			buy_button.disabled = true
		else:
			buy_button.text = "Buy (%d gold)" % cost
			buy_button.disabled = not can_afford(cost)
			buy_button.pressed.connect(func(): purchase_upgrade(upgrade_id))
		vbox.add_child(buy_button)
		
		panel.add_child(vbox)
		upgrade_container.add_child(panel)

func get_upgrade_level(upgrade_id: String) -> int:
	if GameManager and GameManager.persistent_data.permanent_upgrades.has(upgrade_id):
		return GameManager.persistent_data.permanent_upgrades[upgrade_id]
	return 0

func calculate_cost(upgrade_id: String) -> int:
	var upgrade = PERMANENT_UPGRADES[upgrade_id]
	var current_level = get_upgrade_level(upgrade_id)
	return int(upgrade.base_cost * pow(upgrade.cost_scale, current_level))

func can_afford(cost: int) -> bool:
	if GameManager:
		return GameManager.persistent_data.total_gold >= cost
	return false

func purchase_upgrade(upgrade_id: String):
	var cost = calculate_cost(upgrade_id)
	if not can_afford(cost):
		return
	
	if GameManager:
		# Deduct gold
		GameManager.persistent_data.total_gold -= cost
		
		# Increment upgrade level
		if not GameManager.persistent_data.permanent_upgrades.has(upgrade_id):
			GameManager.persistent_data.permanent_upgrades[upgrade_id] = 0
		GameManager.persistent_data.permanent_upgrades[upgrade_id] += 1
		
		# Save
		GameManager.save_persistent_data()
	
	# Refresh UI
	update_gold_display()
	create_upgrade_buttons()
	
	# Play purchase sound/effect
	play_purchase_effect()

func play_purchase_effect():
	# Simple visual feedback
	modulate = Color(1.2, 1.2, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://TitleScreen/menu.tscn")
