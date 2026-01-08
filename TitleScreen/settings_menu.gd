extends CanvasLayer

## Settings Menu - Graphics/Audio options
## Includes window/viewport size selection

signal settings_closed

const RESOLUTION_OPTIONS = [
	{"label": "640x360 (Tiny)", "size": Vector2i(640, 360)},
	{"label": "960x540 (Small)", "size": Vector2i(960, 540)},
	{"label": "1280x720 (HD)", "size": Vector2i(1280, 720)},
	{"label": "1600x900 (HD+)", "size": Vector2i(1600, 900)},
	{"label": "1920x1080 (Full HD)", "size": Vector2i(1920, 1080)},
	{"label": "2560x1440 (2K)", "size": Vector2i(2560, 1440)},
	{"label": "Fullscreen", "size": Vector2i(-1, -1)}  # Special case
]

const SCALE_OPTIONS = [
	{"label": "1x (Pixel Perfect)", "scale": 1.0},
	{"label": "2x (Double)", "scale": 2.0},
	{"label": "3x (Triple)", "scale": 3.0},
	{"label": "4x (Quadruple)", "scale": 4.0}
]

@onready var panel = $Panel
@onready var resolution_dropdown = $Panel/VBox/ResolutionRow/ResolutionDropdown
@onready var scale_dropdown = $Panel/VBox/ScaleRow/ScaleDropdown
@onready var fullscreen_check = $Panel/VBox/FullscreenRow/FullscreenCheck
@onready var close_button = $Panel/VBox/CloseButton
@onready var master_slider = $Panel/VBox/MasterRow/MasterSlider
@onready var sfx_slider = $Panel/VBox/SFXRow/SFXSlider
@onready var music_slider = $Panel/VBox/MusicRow/MusicSlider

var current_resolution_index := 2  # Default to 1280x720
var current_scale_index := 1  # Default to 2x

func _ready():
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	# Populate resolution dropdown
	resolution_dropdown.clear()
	for i in range(RESOLUTION_OPTIONS.size()):
		resolution_dropdown.add_item(RESOLUTION_OPTIONS[i].label, i)
	resolution_dropdown.selected = current_resolution_index
	
	# Populate scale dropdown
	scale_dropdown.clear()
	for i in range(SCALE_OPTIONS.size()):
		scale_dropdown.add_item(SCALE_OPTIONS[i].label, i)
	scale_dropdown.selected = current_scale_index
	
	# Connect signals
	resolution_dropdown.item_selected.connect(_on_resolution_selected)
	scale_dropdown.item_selected.connect(_on_scale_selected)
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	close_button.pressed.connect(_on_close_pressed)
	
	# Audio sliders
	master_slider.value_changed.connect(_on_master_volume_changed)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	music_slider.value_changed.connect(_on_music_volume_changed)
	
	# Load saved settings
	_load_settings()

func show_settings():
	visible = true
	
	# Animate in
	panel.scale = Vector2(0.8, 0.8)
	panel.modulate.a = 0.0
	var tween = create_tween().set_parallel()
	tween.tween_property(panel, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT)
	tween.tween_property(panel, "modulate:a", 1.0, 0.15)

func hide_settings():
	var tween = create_tween().set_parallel()
	tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.15)
	tween.tween_property(panel, "modulate:a", 0.0, 0.15)
	await tween.finished
	visible = false
	emit_signal("settings_closed")

func _on_resolution_selected(index: int):
	current_resolution_index = index
	var resolution = RESOLUTION_OPTIONS[index]
	
	if resolution.size == Vector2i(-1, -1):
		# Fullscreen
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		fullscreen_check.set_pressed_no_signal(true)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolution.size)
		# Center window
		var screen_size = DisplayServer.screen_get_size()
		var window_pos = (screen_size - resolution.size) / 2
		DisplayServer.window_set_position(window_pos)
		fullscreen_check.set_pressed_no_signal(false)
	
	_save_settings()

func _on_scale_selected(index: int):
	current_scale_index = index
	var scale_factor = SCALE_OPTIONS[index].scale
	
	# Update viewport scale
	# The base resolution is 640x360 (retro)
	var base_size = Vector2i(640, 360)
	get_tree().root.content_scale_size = base_size
	get_tree().root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_tree().root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_KEEP
	
	_save_settings()

func _on_fullscreen_toggled(pressed: bool):
	if pressed:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		resolution_dropdown.selected = RESOLUTION_OPTIONS.size() - 1  # Fullscreen option
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		_on_resolution_selected(current_resolution_index)
	
	_save_settings()

func _on_master_volume_changed(value: float):
	var bus_idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	_save_settings()

func _on_sfx_volume_changed(value: float):
	var bus_idx = AudioServer.get_bus_index("SFX")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	_save_settings()

func _on_music_volume_changed(value: float):
	var bus_idx = AudioServer.get_bus_index("Music")
	if bus_idx >= 0:
		AudioServer.set_bus_volume_db(bus_idx, linear_to_db(value))
	_save_settings()

func _on_close_pressed():
	hide_settings()

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		hide_settings()

func _save_settings():
	var config = ConfigFile.new()
	config.set_value("graphics", "resolution_index", current_resolution_index)
	config.set_value("graphics", "scale_index", current_scale_index)
	config.set_value("graphics", "fullscreen", fullscreen_check.button_pressed)
	config.set_value("audio", "master", master_slider.value)
	config.set_value("audio", "sfx", sfx_slider.value)
	config.set_value("audio", "music", music_slider.value)
	config.save("user://settings.cfg")

func _load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	if err != OK:
		return
	
	current_resolution_index = config.get_value("graphics", "resolution_index", 2)
	current_scale_index = config.get_value("graphics", "scale_index", 1)
	var fullscreen = config.get_value("graphics", "fullscreen", false)
	
	resolution_dropdown.selected = current_resolution_index
	scale_dropdown.selected = current_scale_index
	fullscreen_check.set_pressed_no_signal(fullscreen)
	
	# Audio
	master_slider.value = config.get_value("audio", "master", 1.0)
	sfx_slider.value = config.get_value("audio", "sfx", 1.0)
	music_slider.value = config.get_value("audio", "music", 0.7)
	
	# Apply settings
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		_on_resolution_selected(current_resolution_index)
