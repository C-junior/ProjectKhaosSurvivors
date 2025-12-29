extends Control

## Kill Counter UI - Displays kills and combo multiplier
## Add this as a child of the player GUI

@onready var kill_label = $KillLabel
@onready var combo_label = $ComboLabel
@onready var combo_timer = $ComboTimer

var kill_count: int = 0
var combo_count: int = 0
var max_combo: int = 0
var combo_decay_time: float = 2.0  # Seconds before combo resets

func _ready():
	# Connect to GameManager signals
	if GameManager:
		GameManager.enemy_killed.connect(_on_enemy_killed)
	
	update_display()
	
	# Setup combo timer
	combo_timer.wait_time = combo_decay_time
	combo_timer.one_shot = true

func _on_enemy_killed(_enemy_type: String, _position: Vector2):
	kill_count += 1
	combo_count += 1
	max_combo = max(max_combo, combo_count)
	
	# Reset combo timer
	combo_timer.start()
	
	update_display()
	
	# Combo milestone effects
	if combo_count == 10 or combo_count == 25 or combo_count == 50 or combo_count == 100:
		play_combo_effect()

func _on_combo_timer_timeout():
	combo_count = 0
	update_display()

func update_display():
	if kill_label:
		kill_label.text = str(kill_count)
	
	if combo_label:
		if combo_count >= 3:
			combo_label.visible = true
			combo_label.text = str(combo_count) + "x COMBO!"
			
			# Color based on combo level
			if combo_count >= 50:
				combo_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2))  # Red
			elif combo_count >= 25:
				combo_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.0))  # Orange
			elif combo_count >= 10:
				combo_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.0))  # Yellow
			else:
				combo_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))  # White
		else:
			combo_label.visible = false

func play_combo_effect():
	# Scale pop animation
	var tween = create_tween()
	tween.tween_property(combo_label, "scale", Vector2(1.5, 1.5), 0.1)
	tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.2)

func get_combo_bonus() -> float:
	# Returns XP/gold multiplier based on combo
	if combo_count >= 50:
		return 2.0
	elif combo_count >= 25:
		return 1.5
	elif combo_count >= 10:
		return 1.25
	else:
		return 1.0
