extends TextureRect

## Item Container - Displays collected weapon/passive icons in HUD
## Shows evolution-ready glow when weapon reaches max level

var upgrade = null
var item_level: int = 1
var is_weapon: bool = false
var evolution_ready: bool = false

# Glow effect nodes
var glow_tween: Tween = null
var tooltip_popup: PanelContainer = null

func _ready():
	if upgrade != null:
		# Load icon
		$ItemTexture.texture = load(UpgradeDb.UPGRADES[upgrade]["icon"])
		
		# Determine type and level
		is_weapon = UpgradeDb.UPGRADES[upgrade]["type"] == "weapon"
		
		# Extract level from upgrade id (e.g., "icespear4" -> 4)
		var base_name = upgrade.rstrip("0123456789")
		var level_str = upgrade.substr(base_name.length())
		if level_str.is_valid_int():
			item_level = level_str.to_int()
		
		# Check if evolution ready (weapon at level 4)
		if is_weapon and item_level >= 4:
			var weapon_id = base_name
			if GameManager and not GameManager.is_weapon_evolved(weapon_id):
				evolution_ready = true
				_start_evolution_glow()
	
	# Enable mouse events for tooltip
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _start_evolution_glow():
	"""Start pulsing golden glow to indicate evolution is ready."""
	var glow = ColorRect.new()
	glow.name = "EvolutionGlow"
	glow.color = Color(1.0, 0.9, 0.3, 0.4)
	glow.size = size
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(glow)
	move_child(glow, 0)
	_pulse_glow(glow)

func _pulse_glow(glow: ColorRect):
	if not is_instance_valid(glow) or not evolution_ready:
		return
	glow_tween = create_tween().set_loops()
	glow_tween.tween_property(glow, "modulate:a", 1.0, 0.6).set_trans(Tween.TRANS_SINE)
	glow_tween.tween_property(glow, "modulate:a", 0.4, 0.6).set_trans(Tween.TRANS_SINE)

func set_evolved():
	evolution_ready = false
	if glow_tween:
		glow_tween.kill()
	var glow = get_node_or_null("EvolutionGlow")
	if glow:
		glow.queue_free()

func _on_mouse_entered():
	"""Show tooltip on hover."""
	if not upgrade or not UpgradeDb.UPGRADES.has(upgrade):
		return
	
	_show_tooltip()

func _on_mouse_exited():
	"""Hide tooltip."""
	_hide_tooltip()

func _show_tooltip():
	"""Create and display tooltip popup."""
	if tooltip_popup:
		return
	
	var data = UpgradeDb.UPGRADES[upgrade]
	
	tooltip_popup = PanelContainer.new()
	tooltip_popup.name = "Tooltip"
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.border_width_top = 1
	style.border_width_bottom = 1
	style.border_width_left = 1
	style.border_width_right = 1
	style.border_color = Color(0.5, 0.5, 0.6, 0.8)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	tooltip_popup.add_theme_stylebox_override("panel", style)
	
	var vbox = VBoxContainer.new()
	tooltip_popup.add_child(vbox)
	
	# Name
	var name_label = Label.new()
	name_label.text = data.get("displayname", "Unknown")
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(1, 0.9, 0.5))
	vbox.add_child(name_label)
	
	# Level
	var level_label = Label.new()
	level_label.text = "Level %d" % item_level
	level_label.add_theme_font_size_override("font_size", 11)
	level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(level_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = data.get("details", "")
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.custom_minimum_size.x = 150
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	# Evolution info if ready
	if evolution_ready:
		var evo_label = Label.new()
		evo_label.text = "✨ EVOLUTION READY! ✨"
		evo_label.add_theme_font_size_override("font_size", 11)
		evo_label.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
		vbox.add_child(evo_label)
		
		var cost_label = Label.new()
		cost_label.text = "Cost: 400 Gold or 300g + 1 Essence"
		cost_label.add_theme_font_size_override("font_size", 10)
		cost_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.5))
		vbox.add_child(cost_label)
	
	# Position
	tooltip_popup.position = Vector2(global_position.x, global_position.y + size.y + 5)
	
	# Add to root
	var root = get_tree().root.get_node_or_null("Player")
	if root:
		root.add_child(tooltip_popup)
	else:
		get_tree().root.add_child(tooltip_popup)

func _hide_tooltip():
	"""Remove tooltip popup."""
	if tooltip_popup:
		tooltip_popup.queue_free()
		tooltip_popup = null
