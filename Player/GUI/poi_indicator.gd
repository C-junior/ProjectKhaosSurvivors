extends CanvasLayer

## POI Indicator - Shows arrows pointing to off-screen POIs and spawn announcements

@onready var player: Node2D = null
@onready var poi_spawner: Node2D = null

# Arrow indicators for each active POI
var arrows: Dictionary = {}  # poi node -> arrow sprite

# Announcement UI elements
var announcement_label: Label = null
var description_label: Label = null
var quest_label: Label = null
var reward_label: Label = null
var announcement_container: VBoxContainer = null
var announcement_tween: Tween = null

# Quest tracker HUD
var quest_tracker: QuestTracker = null

# Arrow settings
const ARROW_MARGIN: float = 50.0  # Distance from screen edge
const ARROW_SIZE: float = 24.0

func _ready():
	# Wait for other nodes to initialize
	await get_tree().process_frame
	
	player = get_tree().get_first_node_in_group("player")
	poi_spawner = get_tree().get_first_node_in_group("poi_spawner") if get_tree().get_first_node_in_group("poi_spawner") else get_parent().get_node_or_null("POISpawner")
	
	# Try to find POI spawner in parent
	if not poi_spawner:
		var world = get_tree().current_scene
		if world:
			poi_spawner = world.get_node_or_null("POISpawner")
	
	if poi_spawner:
		poi_spawner.poi_spawned.connect(_on_poi_spawned)
		poi_spawner.poi_removed.connect(_on_poi_removed)
	
	# Create announcement label
	_setup_announcement_label()
	
	# Create quest tracker HUD
	_setup_quest_tracker()

func _setup_quest_tracker():
	quest_tracker = QuestTracker.new()
	quest_tracker.name = "QuestTracker"
	get_tree().root.call_deferred("add_child", quest_tracker)
	print("[POI Indicator] Quest tracker created")

func _setup_announcement_label():
	# Create a full-screen Control container for proper anchoring
	var container = Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	
	# Create a VBox for multi-line announcements
	var vbox = VBoxContainer.new()
	vbox.anchor_left = 0.1
	vbox.anchor_right = 0.9
	vbox.anchor_top = 0.0
	vbox.anchor_bottom = 0.0
	vbox.offset_top = 60
	vbox.offset_bottom = 200
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.add_child(vbox)
	
	# Title label (main announcement)
	announcement_label = Label.new()
	announcement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	announcement_label.add_theme_font_size_override("font_size", 28)
	announcement_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))  # Golden
	announcement_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	announcement_label.add_theme_constant_override("outline_size", 5)
	vbox.add_child(announcement_label)
	
	# Description label (visual flavor)
	description_label = Label.new()
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.add_theme_font_size_override("font_size", 16)
	description_label.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0, 0.9))  # Light blue-white
	description_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	description_label.add_theme_constant_override("outline_size", 3)
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(description_label)
	
	# Quest objective label
	quest_label = Label.new()
	quest_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	quest_label.add_theme_font_size_override("font_size", 22)
	quest_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))  # Green
	quest_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	quest_label.add_theme_constant_override("outline_size", 4)
	vbox.add_child(quest_label)
	
	# Reward label
	reward_label = Label.new()
	reward_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward_label.add_theme_font_size_override("font_size", 20)
	reward_label.add_theme_color_override("font_color", Color(1.0, 0.7, 0.2, 1.0))  # Orange-gold
	reward_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	reward_label.add_theme_constant_override("outline_size", 4)
	vbox.add_child(reward_label)
	
	# Store vbox reference for visibility control
	announcement_container = vbox
	announcement_container.visible = false
	
	print("[POI Indicator] Announcement panel created")

func _process(_delta: float):
	if not player:
		return
	
	_update_arrows()

func _update_arrows():
	var viewport_rect = get_viewport().get_visible_rect()
	var screen_center = viewport_rect.size / 2
	
	for poi in arrows.keys():
		if not is_instance_valid(poi):
			# POI was freed, remove arrow
			if is_instance_valid(arrows[poi]):
				arrows[poi].queue_free()
			arrows.erase(poi)
			continue
		
		var arrow = arrows[poi]
		if not is_instance_valid(arrow):
			continue
		
		# Get POI position relative to player (screen center)
		var poi_screen_pos = poi.global_position - player.global_position + screen_center
		
		# Check if POI is on screen
		var margin = 40
		var is_on_screen = (
			poi_screen_pos.x > margin and 
			poi_screen_pos.x < viewport_rect.size.x - margin and
			poi_screen_pos.y > margin and 
			poi_screen_pos.y < viewport_rect.size.y - margin
		)
		
		if is_on_screen:
			arrow.visible = false
		else:
			arrow.visible = true
			
			# Calculate arrow position clamped to screen edge
			var direction = (poi_screen_pos - screen_center).normalized()
			var edge_pos = _get_edge_position(screen_center, direction, viewport_rect.size)
			
			arrow.position = edge_pos
			arrow.rotation = direction.angle()

func _get_edge_position(center: Vector2, direction: Vector2, screen_size: Vector2) -> Vector2:
	# Raycast from center to find intersection with screen edge
	var margin = ARROW_MARGIN
	
	# Calculate intersection with each edge
	var pos = center
	
	if direction.x != 0:
		# Right or left edge
		var target_x = screen_size.x - margin if direction.x > 0 else margin
		var t = (target_x - center.x) / direction.x
		if t > 0:
			var y = center.y + direction.y * t
			if y >= margin and y <= screen_size.y - margin:
				pos = Vector2(target_x, y)
				return pos
	
	if direction.y != 0:
		# Top or bottom edge
		var target_y = screen_size.y - margin if direction.y > 0 else margin
		var t = (target_y - center.y) / direction.y
		if t > 0:
			var x = center.x + direction.x * t
			if x >= margin and x <= screen_size.x - margin:
				pos = Vector2(x, target_y)
				return pos
	
	# Fallback: clamp to screen
	pos = center + direction * 200
	pos.x = clamp(pos.x, margin, screen_size.x - margin)
	pos.y = clamp(pos.y, margin, screen_size.y - margin)
	return pos

func _on_poi_spawned(poi: Node):
	# Create arrow indicator
	var arrow = _create_arrow()
	arrows[poi] = arrow
	add_child(arrow)
	
	# Connect to POI activation to start quest tracking
	if poi.has_signal("poi_activated"):
		poi.poi_activated.connect(_on_poi_activated)
	
	# Show detailed announcement with POI data
	_show_poi_announcement(poi)
	
	# Screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(4.0, 0.5)

func _on_poi_activated(poi: Node):
	# Start quest tracker when player activates a POI
	if quest_tracker:
		quest_tracker.start_tracking(poi)
		print("[POI Indicator] Quest tracking started for: ", poi.name)

func _on_poi_removed(poi: Node):
	if arrows.has(poi):
		if is_instance_valid(arrows[poi]):
			arrows[poi].queue_free()
		arrows.erase(poi)

func _create_arrow() -> Node2D:
	# Create a simple arrow using a polygon
	var arrow = Node2D.new()
	
	# Arrow polygon
	var polygon = Polygon2D.new()
	polygon.polygon = PackedVector2Array([
		Vector2(12, 0),    # Tip
		Vector2(-8, -8),   # Top back
		Vector2(-4, 0),    # Center indent
		Vector2(-8, 8),    # Bottom back
	])
	polygon.color = Color(0.2, 0.8, 1.0, 0.9)  # Cyan
	arrow.add_child(polygon)
	
	# Outline for visibility
	var outline = Polygon2D.new()
	outline.polygon = PackedVector2Array([
		Vector2(15, 0),
		Vector2(-11, -11),
		Vector2(-6, 0),
		Vector2(-11, 11),
	])
	outline.color = Color(0, 0, 0, 0.7)
	outline.z_index = -1
	arrow.add_child(outline)
	
	# Pulsing animation
	var tween = arrow.create_tween().set_loops()
	tween.tween_property(arrow, "scale", Vector2(1.2, 1.2), 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(arrow, "scale", Vector2(1.0, 1.0), 0.5).set_trans(Tween.TRANS_SINE)
	
	return arrow

func _show_poi_announcement(poi: Node):
	if not announcement_container:
		return
	
	# Get POI data
	var poi_name = poi.poi_name if poi.get("poi_name") else "Point of Interest"
	var poi_desc = poi.poi_description if poi.get("poi_description") else ""
	var quest_desc = poi.get_quest_description() if poi.has_method("get_quest_description") else ""
	var reward_desc = poi.get_reward_type_name() if poi.has_method("get_reward_type_name") else ""
	
	# Set label texts
	announcement_label.text = "⚔️ %s APPEARED! ⚔️" % poi_name.to_upper()
	description_label.text = poi_desc
	quest_label.text = quest_desc
	reward_label.text = "🎁 Reward: %s" % reward_desc if reward_desc else ""
	
	# Show container
	announcement_container.visible = true
	announcement_container.modulate = Color(1, 1, 1, 0)
	
	# Cancel previous tween
	if announcement_tween and announcement_tween.is_valid():
		announcement_tween.kill()
	
	# Animate in with slight scale effect, hold longer, animate out
	announcement_tween = create_tween()
	announcement_tween.tween_property(announcement_container, "modulate:a", 1.0, 0.4).set_trans(Tween.TRANS_BACK)
	announcement_tween.tween_interval(4.0)  # Hold for 4 seconds so player can read
	announcement_tween.tween_property(announcement_container, "modulate:a", 0.0, 0.6)
	announcement_tween.tween_callback(func(): announcement_container.visible = false)
	
	print("[POI Indicator] Announcement: %s | Quest: %s | Reward: %s" % [poi_name, quest_desc, reward_desc])
