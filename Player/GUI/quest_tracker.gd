extends CanvasLayer
class_name QuestTracker

## HUD component for displaying active POI quest progress
## Shows kill counters, survival timers, and time remaining

# UI Elements
var container: PanelContainer
var vbox: VBoxContainer
var title_label: Label
var objective_label: Label
var progress_bar: ProgressBar
var time_label: Label

# State
var active_poi: Node = null
var quest_type: String = ""
var is_visible := false

func _ready():
	layer = 100  # Above game UI
	_create_ui()
	hide_tracker()

func _create_ui():
	# Create panel container positioned at top-right
	container = PanelContainer.new()
	container.name = "QuestTrackerPanel"
	
	# Style the panel with semi-transparent dark background
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.85)
	style.border_color = Color(0.3, 0.7, 1.0, 0.8)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 15
	style.content_margin_right = 15
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	container.add_theme_stylebox_override("panel", style)
	
	# Position at top-right
	container.anchor_left = 1.0
	container.anchor_right = 1.0
	container.anchor_top = 0.0
	container.anchor_bottom = 0.0
	container.offset_left = -220
	container.offset_right = -10
	container.offset_top = 80
	container.offset_bottom = 200
	
	add_child(container)
	
	# Create VBox for content
	vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	container.add_child(vbox)
	
	# Title label
	title_label = Label.new()
	title_label.text = "⚔️ QUEST ACTIVE"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 16)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	vbox.add_child(title_label)
	
	# Objective label
	objective_label = Label.new()
	objective_label.text = "Kill 0/25 enemies"
	objective_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	objective_label.add_theme_font_size_override("font_size", 18)
	objective_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))
	objective_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	objective_label.add_theme_constant_override("outline_size", 2)
	vbox.add_child(objective_label)
	
	# Progress bar
	progress_bar = ProgressBar.new()
	progress_bar.min_value = 0
	progress_bar.max_value = 100
	progress_bar.value = 0
	progress_bar.show_percentage = false
	progress_bar.custom_minimum_size = Vector2(180, 16)
	
	# Style progress bar
	var bar_bg = StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.2, 0.2, 0.3, 0.8)
	bar_bg.set_corner_radius_all(4)
	progress_bar.add_theme_stylebox_override("background", bar_bg)
	
	var bar_fill = StyleBoxFlat.new()
	bar_fill.bg_color = Color(0.3, 0.8, 1.0, 1.0)
	bar_fill.set_corner_radius_all(4)
	progress_bar.add_theme_stylebox_override("fill", bar_fill)
	
	vbox.add_child(progress_bar)
	
	# Time label
	time_label = Label.new()
	time_label.text = "⏱️ 25.0s remaining"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 14)
	time_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.9))
	vbox.add_child(time_label)
	
	print("[Quest Tracker] UI created")

func show_tracker():
	container.visible = true
	is_visible = true
	
	# Animate in
	container.modulate = Color(1, 1, 1, 0)
	var tween = create_tween()
	tween.tween_property(container, "modulate:a", 1.0, 0.3)

func hide_tracker():
	if not container:
		return
	
	var tween = create_tween()
	tween.tween_property(container, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func(): 
		container.visible = false
		is_visible = false
		active_poi = null
	)

func start_tracking(poi: Node):
	active_poi = poi
	
	# Connect to POI signals
	if poi.has_signal("quest_progress_updated"):
		if not poi.quest_progress_updated.is_connected(_on_quest_progress):
			poi.quest_progress_updated.connect(_on_quest_progress)
	if poi.has_signal("quest_time_updated"):
		if not poi.quest_time_updated.is_connected(_on_quest_time):
			poi.quest_time_updated.connect(_on_quest_time)
	if poi.has_signal("poi_completed"):
		if not poi.poi_completed.is_connected(_on_poi_completed):
			poi.poi_completed.connect(_on_poi_completed)
	
	# Determine quest type and set title
	if poi.has_method("get_quest_description"):
		var quest_desc = poi.get_quest_description()
		if "Kill" in quest_desc:
			quest_type = "kill"
			title_label.text = "⚔️ KILL CHALLENGE"
		else:
			quest_type = "survival"
			title_label.text = "🛡️ SURVIVAL CHALLENGE"
	
	show_tracker()
	print("[Quest Tracker] Started tracking POI: ", poi.name)

func stop_tracking():
	if active_poi:
		# Disconnect signals
		if active_poi.has_signal("quest_progress_updated"):
			if active_poi.quest_progress_updated.is_connected(_on_quest_progress):
				active_poi.quest_progress_updated.disconnect(_on_quest_progress)
		if active_poi.has_signal("quest_time_updated"):
			if active_poi.quest_time_updated.is_connected(_on_quest_time):
				active_poi.quest_time_updated.disconnect(_on_quest_time)
		if active_poi.has_signal("poi_completed"):
			if active_poi.poi_completed.is_connected(_on_poi_completed):
				active_poi.poi_completed.disconnect(_on_poi_completed)
	
	hide_tracker()

func _on_quest_progress(current: int, target: int, type: String):
	quest_type = type
	objective_label.text = "⚔️ %d / %d kills" % [current, target]
	progress_bar.value = float(current) / float(target) * 100.0
	
	# Update bar color based on progress
	var bar_fill = progress_bar.get_theme_stylebox("fill") as StyleBoxFlat
	if bar_fill:
		var progress_pct = float(current) / float(target)
		if progress_pct >= 0.75:
			bar_fill.bg_color = Color(0.3, 1.0, 0.3, 1.0)  # Green when close
		elif progress_pct >= 0.5:
			bar_fill.bg_color = Color(1.0, 0.8, 0.2, 1.0)  # Yellow mid-way
		else:
			bar_fill.bg_color = Color(0.3, 0.8, 1.0, 1.0)  # Cyan starting

func _on_quest_time(time_remaining: float, in_zone: bool):
	# Always update the time label for both quest types
	update_time_remaining(time_remaining)
	
	# For survival quest, update objective label with zone status
	if quest_type == "survival":
		if in_zone:
			objective_label.text = "🛡️ %.1fs remaining" % time_remaining
			objective_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))
		else:
			objective_label.text = "⚠️ RETURN TO ZONE!"
			objective_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
		
		# Calculate progress (inverted - starts at 0, fills as time passes)
		if active_poi and active_poi.get("survival_time"):
			var total = active_poi.survival_time
			progress_bar.value = (1.0 - (time_remaining / total)) * 100.0

func _on_poi_completed(poi: Node, success: bool):
	if poi == active_poi:
		if success:
			objective_label.text = "✅ QUEST COMPLETE!"
			objective_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))
			progress_bar.value = 100
		else:
			objective_label.text = "❌ QUEST FAILED"
			objective_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
		
		# Hide after delay
		await get_tree().create_timer(2.0).timeout
		stop_tracking()

func update_time_remaining(time: float):
	time_label.text = "⏱️ %.1fs remaining" % time
	
	# Color based on urgency
	if time <= 5.0:
		time_label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
	elif time <= 10.0:
		time_label.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2, 1.0))
	else:
		time_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 0.9))
