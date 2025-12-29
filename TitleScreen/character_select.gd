extends Control

## Character Selection Screen
## Players choose their starting character before a run

@onready var character_container = $CharacterContainer
@onready var start_button = $StartButton
@onready var character_name = $CharacterInfo/CharacterName
@onready var character_desc = $CharacterInfo/CharacterDesc
@onready var character_stats = $CharacterInfo/CharacterStats

var selected_character := "mage"

const CHARACTERS = {
	"mage": {
		"name": "Mage",
		"description": "Master of ice magic. Starts with Ice Spear.",
		"starting_weapon": "icespear1",
		"sprite": "res://Textures/Player/player_sprite.png",
		"stats": {
			"hp_bonus": 0,
			"speed_bonus": 0,
			"spell_size_bonus": 0.20,
			"spell_cooldown_bonus": 0.0
		},
		"color": Color(0.4, 0.6, 1.0)
	},
	"knight": {
		"name": "Knight",
		"description": "Armored warrior. Starts with Holy Cross.",
		"starting_weapon": "holycross1",
		"sprite": "res://Textures/Player/knight.png",
		"stats": {
			"hp_bonus": 30,
			"speed_bonus": -10,
			"spell_size_bonus": 0.0,
			"spell_cooldown_bonus": 0.0
		},
		"color": Color(0.8, 0.7, 0.3)
	},
	"rogue": {
		"name": "Rogue",
		"description": "Swift and lucky. Starts with Lightning.",
		"starting_weapon": "lightning1",
		"sprite": "res://Textures/Player/rogue.png",
		"stats": {
			"hp_bonus": -20,
			"speed_bonus": 30,
			"spell_size_bonus": 0.0,
			"spell_cooldown_bonus": 0.10
		},
		"color": Color(0.6, 0.3, 0.8)
	}
}

func _ready():
	create_character_buttons()
	select_character("mage")

func create_character_buttons():
	for char_id in CHARACTERS:
		var char_data = CHARACTERS[char_id]
		
		var button = Button.new()
		button.text = char_data.name
		button.custom_minimum_size = Vector2(100, 80)
		button.pressed.connect(func(): select_character(char_id))
		
		# Style the button with character color
		var style = StyleBoxFlat.new()
		style.bg_color = char_data.color * 0.5
		style.border_width_bottom = 3
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_color = char_data.color
		style.corner_radius_bottom_left = 8
		style.corner_radius_bottom_right = 8
		style.corner_radius_top_left = 8
		style.corner_radius_top_right = 8
		button.add_theme_stylebox_override("normal", style)
		
		character_container.add_child(button)

func select_character(char_id: String):
	selected_character = char_id
	var char_data = CHARACTERS[char_id]
	
	# Update info display
	character_name.text = char_data.name
	character_desc.text = char_data.description
	
	# Build stats text
	var stats_text = ""
	if char_data.stats.hp_bonus != 0:
		var sign = "+" if char_data.stats.hp_bonus > 0 else ""
		stats_text += "HP: %s%d\n" % [sign, char_data.stats.hp_bonus]
	if char_data.stats.speed_bonus != 0:
		var sign = "+" if char_data.stats.speed_bonus > 0 else ""
		stats_text += "Speed: %s%d%%\n" % [sign, char_data.stats.speed_bonus]
	if char_data.stats.spell_size_bonus != 0:
		stats_text += "Spell Size: +%d%%\n" % [int(char_data.stats.spell_size_bonus * 100)]
	if char_data.stats.spell_cooldown_bonus != 0:
		stats_text += "Cooldown: -%d%%\n" % [int(char_data.stats.spell_cooldown_bonus * 100)]
	
	if stats_text == "":
		stats_text = "No stat bonuses"
	
	character_stats.text = stats_text
	
	# Highlight selected button
	for button in character_container.get_children():
		if button is Button:
			button.modulate = Color(0.6, 0.6, 0.6) if button.text != char_data.name else Color.WHITE

func _on_start_button_pressed():
	# Store selected character in GameManager
	if GameManager:
		GameManager.current_run.character = selected_character
		var char_data = CHARACTERS[selected_character]
		
		# Apply stat bonuses
		GameManager.player_stats.max_hp += char_data.stats.hp_bonus
		GameManager.player_stats.hp = GameManager.player_stats.max_hp
		GameManager.player_stats.movement_speed += char_data.stats.speed_bonus
		GameManager.player_stats.spell_size += char_data.stats.spell_size_bonus
		GameManager.player_stats.spell_cooldown += char_data.stats.spell_cooldown_bonus
		
		# Store starting weapon and sprite
		GameManager.current_run.weapons.append(char_data.starting_weapon)
		GameManager.current_run.sprite = char_data.sprite
	
	# Start the game
	get_tree().change_scene_to_file("res://World/world.tscn")

func _on_back_button_pressed():
	get_tree().change_scene_to_file("res://TitleScreen/menu.tscn")
