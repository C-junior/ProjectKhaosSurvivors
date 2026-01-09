extends POIBase
class_name CursedChest

## Cursed Chest POI - Risk/Reward gold with a penalty
## Gives bonus gold but applies a temporary curse

enum CurseType {
	SLOW,       # -30% movement speed for 30s
	FRAGILE,    # +50% damage taken for 20s
	BLIND,      # Reduced vision range for 15s
	WEAK        # -20% damage dealt for 25s
}

@export var gold_reward_min: int = 100
@export var gold_reward_max: int = 200
@export var curse_duration: float = 20.0

var selected_curse: CurseType
var gold_amount: int = 0
var curse_applied: bool = false

@onready var chest_sprite: Sprite2D = $ChestSprite if has_node("ChestSprite") else null
@onready var curse_label: Label = $CurseLabel if has_node("CurseLabel") else null

func _ready():
	super._ready()
	
	poi_name = "Cursed Chest"
	poi_description = "A chest emanating dark energy... riches await, but at what cost?"
	reward_description = "Cursed Gold"
	glow_color = Color(0.8, 0.2, 0.2, 1.0)  # Red glow
	
	# Randomize reward and curse
	gold_amount = randi_range(gold_reward_min, gold_reward_max)
	selected_curse = CurseType.values().pick_random()

func get_quest_description() -> String:
	return "💀 Open the cursed chest?"

func get_reward_type_name() -> String:
	return "💰 %d Gold + Curse" % gold_amount

func _get_curse_name() -> String:
	match selected_curse:
		CurseType.SLOW: return "Sluggish"
		CurseType.FRAGILE: return "Fragile"
		CurseType.BLIND: return "Blinded"
		CurseType.WEAK: return "Weakened"
	return "Cursed"

func _get_curse_description() -> String:
	match selected_curse:
		CurseType.SLOW: return "-30% Speed"
		CurseType.FRAGILE: return "+50% Damage Taken"
		CurseType.BLIND: return "Reduced Vision"
		CurseType.WEAK: return "-20% Damage"
	return "???"

func activate():
	if is_active or is_expired or is_completed:
		return
	
	super.activate()
	
	# Chest opening animation
	if chest_sprite:
		var tween = create_tween()
		tween.tween_property(chest_sprite, "rotation_degrees", 15, 0.1)
		tween.tween_property(chest_sprite, "rotation_degrees", -10, 0.1)
		tween.tween_property(chest_sprite, "rotation_degrees", 0, 0.1)
	
	# Dark flash
	modulate = Color(0.6, 0.2, 0.2, 1.0)
	var flash_tween = create_tween()
	flash_tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	await get_tree().create_timer(0.5).timeout
	
	complete(true)  # Always "succeeds" but applies curse

func _grant_reward():
	"""Grant gold and apply curse."""
	# Give gold
	if GameManager:
		GameManager.add_gold(gold_amount)
	
	if GameEvents:
		GameEvents.emit_resource_gain("gold", gold_amount)
	
	# Apply curse
	_apply_curse()
	
	# Show result
	_show_curse_warning()

func _apply_curse():
	"""Apply the curse effect to the player."""
	curse_applied = true
	
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	match selected_curse:
		CurseType.SLOW:
			if player.has_method("apply_curse_slow"):
				player.apply_curse_slow(curse_duration)
			else:
				# Fallback: directly modify speed
				var original_speed = player.movement_speed
				player.movement_speed *= 0.7
				_schedule_curse_removal(func(): player.movement_speed = original_speed, curse_duration)
		
		CurseType.FRAGILE:
			if player.has_method("apply_curse_fragile"):
				player.apply_curse_fragile(curse_duration)
			else:
				var original_armor = player.armor
				player.armor -= 5
				_schedule_curse_removal(func(): player.armor = original_armor, curse_duration)
		
		CurseType.WEAK:
			if player.has_method("apply_curse_weak"):
				player.apply_curse_weak(curse_duration)
			else:
				var original_damage = player.damage_bonus
				player.damage_bonus -= 0.20
				_schedule_curse_removal(func(): player.damage_bonus = original_damage, curse_duration)
		
		CurseType.BLIND:
			# Reduce camera zoom temporarily
			var camera = get_viewport().get_camera_2d()
			if camera:
				var original_zoom = camera.zoom
				camera.zoom = original_zoom * 0.7
				_schedule_curse_removal(func(): camera.zoom = original_zoom, curse_duration)
	
	# Notify buff system
	if player.has_method("add_buff_indicator"):
		player.add_buff_indicator("curse_%s" % _get_curse_name().to_lower(), curse_duration)

func _schedule_curse_removal(removal_func: Callable, duration: float):
	"""Schedule curse removal after duration."""
	await get_tree().create_timer(duration).timeout
	if removal_func:
		removal_func.call()

func _show_curse_warning():
	"""Display curse warning to player."""
	var label = Label.new()
	label.text = "+%d Gold\n%s (%.0fs)" % [gold_amount, _get_curse_description(), curse_duration]
	label.modulate = Color(1.0, 0.3, 0.3, 1.0)
	label.add_theme_font_size_override("font_size", 16)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.global_position = global_position + Vector2(-60, -50)
	get_parent().add_child(label)
	
	var tween = create_tween()
	tween.tween_property(label, "global_position:y", label.global_position.y - 50, 1.2)
	tween.parallel().tween_property(label, "modulate:a", 0.0, 1.5)
	tween.chain().tween_callback(label.queue_free)

func _play_success_effect():
	# Dark burst instead of golden
	modulate = Color(0.4, 0.1, 0.1, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * 1.3, 0.2)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
	
	# Red/dark particles
	_spawn_curse_particles()

func _spawn_curse_particles():
	"""Dark particles for curse."""
	for i in range(8):
		var particle = Sprite2D.new()
		particle.modulate = Color(0.6, 0.1, 0.1, 1)
		particle.global_position = global_position
		get_parent().add_child(particle)
		
		var angle = i * (TAU / 8)
		var target_pos = global_position + Vector2(cos(angle), sin(angle)) * 50
		
		var tween = particle.create_tween().set_parallel(true)
		tween.tween_property(particle, "global_position", target_pos, 0.4)
		tween.tween_property(particle, "modulate:a", 0.0, 0.6)
		tween.chain().tween_callback(particle.queue_free)
