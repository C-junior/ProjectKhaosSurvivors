extends CanvasLayer

## POI Indicator - Shows arrows pointing to off-screen POIs and spawn announcements

@onready var player: Node2D = null
@onready var poi_spawner: Node2D = null

# Arrow indicators for each active POI
var arrows: Dictionary = {}  # poi node -> arrow sprite

# Announcement label
var announcement_label: Label = null
var announcement_tween: Tween = null

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

func _setup_announcement_label():
	# Create a full-screen Control container for proper anchoring
	var container = Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	
	# Create the label
	announcement_label = Label.new()
	announcement_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	announcement_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	announcement_label.add_theme_font_size_override("font_size", 32)
	announcement_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3, 1.0))
	announcement_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	announcement_label.add_theme_constant_override("outline_size", 6)
	
	# Use anchors to center horizontally at top of screen
	announcement_label.anchor_left = 0.0
	announcement_label.anchor_right = 1.0
	announcement_label.anchor_top = 0.0
	announcement_label.anchor_bottom = 0.0
	announcement_label.offset_left = 0
	announcement_label.offset_right = 0
	announcement_label.offset_top = 80
	announcement_label.offset_bottom = 130
	announcement_label.visible = false
	
	container.add_child(announcement_label)
	print("[POI Indicator] Announcement label created")

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
	
	# Show announcement
	_show_announcement("⚔️ CHALLENGE SHRINE APPEARED! ⚔️")
	
	# Screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(4.0, 0.5)

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

func _show_announcement(text: String):
	if not announcement_label:
		return
	
	announcement_label.text = text
	announcement_label.visible = true
	announcement_label.modulate = Color(1, 1, 1, 0)
	
	# Cancel previous tween
	if announcement_tween and announcement_tween.is_valid():
		announcement_tween.kill()
	
	# Animate in, hold, animate out
	announcement_tween = create_tween()
	announcement_tween.tween_property(announcement_label, "modulate:a", 1.0, 0.3)
	announcement_tween.tween_interval(2.5)
	announcement_tween.tween_property(announcement_label, "modulate:a", 0.0, 0.5)
	announcement_tween.tween_callback(func(): announcement_label.visible = false)
