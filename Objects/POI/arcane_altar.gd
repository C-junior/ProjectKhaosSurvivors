extends POIBase
class_name ArcaneAltar

## Arcane Altar POI - Essence gambling mechanic
## Player can attempt to gain bonus essence, but risks losing it all

@export var base_essence_reward: int = 1
@export var success_chance: float = 0.65  # 65% success rate
@export var bonus_multiplier: float = 2.0  # Win 2x essence on success
@export var essence_cost: int = 0  # Free to attempt (risk is the gamble itself)

var gamble_result: bool = false
var reward_amount: int = 0

@onready var altar_glow: Sprite2D = $AltarGlow if has_node("AltarGlow") else null
@onready var result_label: Label = $ResultLabel if has_node("ResultLabel") else null

func _ready():
	super._ready()
	
	poi_name = "Arcane Altar"
	poi_description = "An ancient altar pulsing with mysterious energy..."
	reward_description = "Essence Gamble"
	glow_color = Color(0.6, 0.3, 1.0, 1.0)  # Purple glow
	
	# Calculate potential reward
	reward_amount = int(base_essence_reward * bonus_multiplier)

func get_quest_description() -> String:
	return "✨ Touch the altar to test your luck!"

func get_reward_type_name() -> String:
	return "💎 %d Essence (%.0f%% chance)" % [reward_amount, success_chance * 100]

func activate():
	if is_active or is_expired or is_completed:
		return
	
	super.activate()
	
	# Immediately resolve the gamble
	gamble_result = randf() <= success_chance
	
	# Visual anticipation
	if altar_glow:
		var tween = create_tween()
		tween.tween_property(altar_glow, "modulate:a", 1.0, 0.3)
		tween.tween_property(altar_glow, "scale", Vector2(1.5, 1.5), 0.3)
	
	# Dramatic pause before result
	await get_tree().create_timer(0.8).timeout
	
	complete(gamble_result)

func _grant_reward():
	"""Grant essence on success."""
	if not gamble_result:
		return
	
	if GameManager:
		GameManager.add_essence(reward_amount)
	
	# Emit event
	if GameEvents:
		GameEvents.emit_resource_gain("essence", reward_amount)
	
	# Show result
	_show_result_text("+" + str(reward_amount) + " Essence!", Color(0.6, 0.3, 1.0))

func _play_success_effect():
	super._play_success_effect()
	
	# Purple burst
	modulate = Color(0.8, 0.4, 1.2, 1.0)
	
	# Screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(8.0, 0.5)
	
	# Particles
	if has_method("spawn_reward_particles"):
		spawn_reward_particles()

func _play_failure_effect():
	super._play_failure_effect()
	
	_show_result_text("Nothing happened...", Color(0.5, 0.5, 0.5))

func _show_result_text(text: String, color: Color):
	if result_label:
		result_label.text = text
		result_label.modulate = color
		result_label.visible = true
		
		var tween = create_tween()
		tween.tween_property(result_label, "position:y", result_label.position.y - 30, 0.5)
		tween.parallel().tween_property(result_label, "modulate:a", 0.0, 0.8)
	else:
		# Create floating text
		var label = Label.new()
		label.text = text
		label.modulate = color
		label.add_theme_font_size_override("font_size", 18)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.global_position = global_position + Vector2(-50, -40)
		get_parent().add_child(label)
		
		var tween = create_tween()
		tween.tween_property(label, "global_position:y", label.global_position.y - 40, 0.8)
		tween.parallel().tween_property(label, "modulate:a", 0.0, 1.0)
		tween.chain().tween_callback(label.queue_free)

func spawn_reward_particles():
	"""Purple sparkle particles for essence."""
	for i in range(10):
		var sparkle = Sprite2D.new()
		sparkle.modulate = Color(0.7, 0.4, 1.0, 1)
		sparkle.global_position = global_position
		get_parent().add_child(sparkle)
		
		var angle = i * (TAU / 10)
		var target_pos = global_position + Vector2(cos(angle), sin(angle)) * 60
		
		var tween = sparkle.create_tween().set_parallel(true)
		tween.tween_property(sparkle, "global_position", target_pos, 0.5).set_trans(Tween.TRANS_QUAD)
		tween.tween_property(sparkle, "modulate:a", 0.0, 0.7)
		tween.chain().tween_callback(sparkle.queue_free)
