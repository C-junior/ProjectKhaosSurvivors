extends CanvasLayer

## Evolution Popup - Displays when a weapon is ready to evolve
## Shows dual-path options with costs and lets player choose

signal evolution_selected(weapon_id: String, evolution_data: Dictionary)
signal evolution_cancelled()

@onready var panel = $Panel
@onready var title_label = $Panel/VBox/TitleLabel
@onready var weapon_icon = $Panel/VBox/WeaponIcon
@onready var options_container = $Panel/VBox/OptionsContainer
@onready var close_button = $Panel/VBox/CloseButton
@onready var gold_label = $Panel/VBox/ResourcesBar/GoldLabel
@onready var essence_label = $Panel/VBox/ResourcesBar/EssenceLabel

var current_weapon_id: String = ""
var evolution_option_scene = preload("res://Player/GUI/evolution_option.tscn")

func _ready():
	visible = false
	close_button.pressed.connect(_on_close_pressed)

func show_evolution(weapon_id: String, weapon_name: String, evolutions: Array):
	"""Display evolution options for a weapon."""
	current_weapon_id = weapon_id
	
	# Update title
	title_label.text = weapon_name + " is ready to evolve!"
	
	# Update resource display
	update_resource_display()
	
	# Clear old options
	for child in options_container.get_children():
		child.queue_free()
	
	# Wait for children to be freed
	await get_tree().process_frame
	
	# Create evolution option cards
	for evo in evolutions:
		var option = evolution_option_scene.instantiate()
		options_container.add_child(option)
		option.setup(evo.data, evo.can_afford, evo.path)
		option.selected.connect(_on_evolution_selected.bind(evo.data))
	
	# Show popup with animation
	visible = true
	panel.modulate.a = 0
	panel.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween().set_parallel()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)
	
	# Pause the game
	get_tree().paused = true

func update_resource_display():
	gold_label.text = str(GameManager.get_gold()) + " Gold"
	essence_label.text = str(GameManager.get_essence()) + " Essence"

func _on_evolution_selected(evolution_data: Dictionary):
	# Check if player can afford
	var gold = GameManager.get_gold()
	var essence = GameManager.get_essence()
	
	if gold < evolution_data.get("cost_gold", 0):
		# Shake the button to indicate not enough gold
		_shake_panel()
		return
	
	if essence < evolution_data.get("cost_essence", 0):
		# Shake the button to indicate not enough essence
		_shake_panel()
		return
	
	# Emit signal for player.gd to handle the actual evolution
	emit_signal("evolution_selected", current_weapon_id, evolution_data)
	
	# Close popup with animation
	_close_popup()

func _on_close_pressed():
	emit_signal("evolution_cancelled")
	_close_popup()

func _close_popup():
	var tween = create_tween().set_parallel()
	tween.tween_property(panel, "modulate:a", 0.0, 0.15)
	tween.tween_property(panel, "scale", Vector2(0.8, 0.8), 0.15)
	
	await tween.finished
	visible = false
	get_tree().paused = false

func _shake_panel():
	var original_pos = panel.position
	var tween = create_tween()
	for i in range(4):
		tween.tween_property(panel, "position:x", original_pos.x + 10, 0.05)
		tween.tween_property(panel, "position:x", original_pos.x - 10, 0.05)
	tween.tween_property(panel, "position:x", original_pos.x, 0.05)

func _input(event):
	if visible and event.is_action_pressed("ui_cancel"):
		_on_close_pressed()
