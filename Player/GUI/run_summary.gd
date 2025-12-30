extends CanvasLayer

## Run Summary Screen - Shows detailed stats at end of run
## Displays kills, time, gold, damage dealt, weapons collected

@onready var panel = $Panel
@onready var lbl_title = $Panel/VBoxContainer/Title
@onready var lbl_time = $Panel/VBoxContainer/StatsGrid/TimeValue
@onready var lbl_kills = $Panel/VBoxContainer/StatsGrid/KillsValue
@onready var lbl_gold = $Panel/VBoxContainer/StatsGrid/GoldValue
@onready var lbl_damage = $Panel/VBoxContainer/StatsGrid/DamageValue
@onready var lbl_level = $Panel/VBoxContainer/StatsGrid/LevelValue
@onready var weapons_container = $Panel/VBoxContainer/WeaponsContainer
@onready var btn_menu = $Panel/VBoxContainer/BtnMenu

var is_victory := false

signal return_to_menu

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	btn_menu.pressed.connect(_on_menu_pressed)

func show_summary(victory: bool, stats: Dictionary):
	is_victory = victory
	visible = true
	
	# Set title based on result
	if victory:
		lbl_title.text = "VICTORY!"
		lbl_title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))  # Gold
	else:
		lbl_title.text = "DEFEATED"
		lbl_title.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3))  # Red
	
	# Format time
	var minutes = int(stats.get("time", 0) / 60)
	var seconds = stats.get("time", 0) % 60
	lbl_time.text = "%02d:%02d" % [minutes, seconds]
	
	# Stats
	lbl_kills.text = str(stats.get("kills", 0))
	lbl_gold.text = str(stats.get("gold", 0))
	lbl_damage.text = str(stats.get("damage_dealt", 0))
	lbl_level.text = str(stats.get("level", 1))
	
	# Display collected weapons
	for child in weapons_container.get_children():
		child.queue_free()
	
	var weapons = stats.get("weapons", [])
	for weapon in weapons:
		var icon = TextureRect.new()
		icon.custom_minimum_size = Vector2(24, 24)
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		# Try to load weapon icon
		if UpgradeDb.UPGRADES.has(weapon):
			var icon_path = UpgradeDb.UPGRADES[weapon].get("icon", "")
			if icon_path != "" and ResourceLoader.exists(icon_path):
				icon.texture = load(icon_path)
		weapons_container.add_child(icon)
	
	# Animate panel in
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)

func _on_menu_pressed():
	emit_signal("return_to_menu")
	get_tree().paused = false
	get_tree().change_scene_to_file("res://TitleScreen/menu.tscn")
