extends CanvasLayer

## Pause Menu - Press ESC to pause the game
## Provides pause functionality with resume, options, and quit buttons

signal resumed
signal quit_to_menu

@onready var panel = $Panel
@onready var btn_resume = $Panel/VBoxContainer/BtnResume
@onready var btn_menu = $Panel/VBoxContainer/BtnMenu

var is_paused := false

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Process even when paused
	
	# Connect buttons
	btn_resume.pressed.connect(_on_resume_pressed)
	btn_menu.pressed.connect(_on_menu_pressed)

func _input(event):
	if event.is_action_pressed("pause"):
		toggle_pause()

func toggle_pause():
	if get_tree().paused and not visible:
		# Already paused by something else (like level-up), don't interfere
		return
	
	is_paused = !is_paused
	get_tree().paused = is_paused
	visible = is_paused
	
	if is_paused:
		# Animate panel in
		panel.scale = Vector2(0.8, 0.8)
		panel.modulate.a = 0.0
		var tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(panel, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)
		tween.tween_property(panel, "modulate:a", 1.0, 0.15)

func _on_resume_pressed():
	toggle_pause()
	emit_signal("resumed")

func _on_menu_pressed():
	is_paused = false
	get_tree().paused = false
	visible = false
	emit_signal("quit_to_menu")
	get_tree().change_scene_to_file("res://TitleScreen/menu.tscn")
