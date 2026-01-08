extends HBoxContainer

## Buff Indicator Bar - Shows active passive effects with visual feedback

# Buff indicator configuration
const BUFF_ICONS = {
	"blood_pact": {"color": Color(0.8, 0.2, 0.2), "label": "BP"},
	"overcharge": {"color": Color(0.2, 0.8, 1.0), "label": "OC"},
	"arcane_echo": {"color": Color(0.6, 0.3, 1.0), "label": "AE"},
	"second_wind": {"color": Color(0.3, 1.0, 0.5), "label": "SW"},
	"second_wind_resist": {"color": Color(1.0, 0.9, 0.3), "label": "⚡"}
}

var active_buffs: Dictionary = {}  # buff_id -> {node, timer, stacks}

func _ready():
	# Set up container properties
	add_theme_constant_override("separation", 4)

func add_buff(buff_id: String, duration: float = -1, stacks: int = 1):
	"""Add or update a buff indicator."""
	if active_buffs.has(buff_id):
		# Update existing buff
		var buff_data = active_buffs[buff_id]
		buff_data.stacks = stacks
		buff_data.timer = duration
		_update_buff_display(buff_id)
	else:
		# Create new buff indicator
		var icon = _create_buff_icon(buff_id)
		add_child(icon)
		active_buffs[buff_id] = {
			"node": icon,
			"timer": duration,
			"stacks": stacks
		}
		# Animate in
		icon.modulate.a = 0
		icon.scale = Vector2(0.5, 0.5)
		var tween = create_tween().set_parallel()
		tween.tween_property(icon, "modulate:a", 1.0, 0.2)
		tween.tween_property(icon, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

func remove_buff(buff_id: String):
	"""Remove a buff indicator with animation."""
	if not active_buffs.has(buff_id):
		return
	
	var buff_data = active_buffs[buff_id]
	var icon = buff_data.node
	
	# Animate out
	var tween = create_tween().set_parallel()
	tween.tween_property(icon, "modulate:a", 0.0, 0.15)
	tween.tween_property(icon, "scale", Vector2(0.5, 0.5), 0.15)
	tween.chain().tween_callback(icon.queue_free)
	
	active_buffs.erase(buff_id)

func update_buff_stacks(buff_id: String, stacks: int):
	"""Update stack count for a buff."""
	if active_buffs.has(buff_id):
		active_buffs[buff_id].stacks = stacks
		_update_buff_display(buff_id)
		
		# Pulse animation on stack change
		var icon = active_buffs[buff_id].node
		var tween = create_tween()
		tween.tween_property(icon, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(icon, "scale", Vector2.ONE, 0.1)

func _create_buff_icon(buff_id: String) -> PanelContainer:
	"""Create a visual buff indicator."""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(32, 32)
	
	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = BUFF_ICONS.get(buff_id, {"color": Color.WHITE}).color
	style.bg_color.a = 0.8
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = BUFF_ICONS.get(buff_id, {"color": Color.WHITE}).color
	panel.add_theme_stylebox_override("panel", style)
	
	# Label
	var label = Label.new()
	label.text = BUFF_ICONS.get(buff_id, {"label": "?"}).label
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 14)
	panel.add_child(label)
	
	# Stack label (bottom right)
	var stack_label = Label.new()
	stack_label.name = "StackLabel"
	stack_label.text = ""
	stack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stack_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	stack_label.add_theme_font_size_override("font_size", 10)
	stack_label.add_theme_color_override("font_color", Color.WHITE)
	panel.add_child(stack_label)
	
	return panel

func _update_buff_display(buff_id: String):
	"""Update the visual display of a buff."""
	if not active_buffs.has(buff_id):
		return
	
	var buff_data = active_buffs[buff_id]
	var icon = buff_data.node
	var stack_label = icon.get_node_or_null("StackLabel")
	
	if stack_label and buff_data.stacks > 1:
		stack_label.text = "x%d" % buff_data.stacks

func _process(delta):
	"""Update buff timers."""
	var to_remove = []
	
	for buff_id in active_buffs:
		var buff_data = active_buffs[buff_id]
		if buff_data.timer > 0:
			buff_data.timer -= delta
			if buff_data.timer <= 0:
				to_remove.append(buff_id)
	
	for buff_id in to_remove:
		remove_buff(buff_id)
