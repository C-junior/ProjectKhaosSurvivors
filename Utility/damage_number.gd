extends Node2D

## Floating Damage Numbers - Shows damage dealt to enemies
## Spawn this at enemy position when damage is dealt

@export var damage_amount: int = 0
@export var is_critical: bool = false
@export var color: Color = Color.WHITE
@export var damage_type: String = "normal"  # normal, fire, ice, lightning, healing

var velocity := Vector2.ZERO
var lifetime := 0.0
var max_lifetime := 1.0
var base_scale := Vector2.ONE

func _ready():
	# Random horizontal offset for variety
	velocity = Vector2(randf_range(-40, 40), -100)
	
	# Color and scale based on damage type/amount
	match damage_type:
		"fire":
			color = Color(1.0, 0.4, 0.1, 1.0)  # Orange
		"ice":
			color = Color(0.4, 0.8, 1.0, 1.0)  # Light blue
		"lightning":
			color = Color(0.9, 0.9, 0.2, 1.0)  # Yellow
		"healing":
			color = Color(0.3, 1.0, 0.3, 1.0)  # Green
			velocity.y = -60  # Slower rise for heals
		_:
			# Scale color based on damage amount
			if damage_amount >= 20:
				color = Color(1.0, 0.8, 0.2, 1.0)  # Gold for big hits
			elif damage_amount >= 10:
				color = Color(1.0, 0.5, 0.2, 1.0)  # Orange for medium hits
			else:
				color = Color.WHITE
	
	# Critical hit styling
	if is_critical:
		color = Color(1.0, 0.2, 0.1, 1.0)  # Bright red for crits
		base_scale = Vector2(1.8, 1.8)
		velocity.y = -120  # Higher jump for crits
		max_lifetime = 1.2  # Stay longer
	else:
		# Scale based on damage for non-crits
		var scale_bonus = clamp(damage_amount / 30.0, 0.0, 0.5)
		base_scale = Vector2.ONE * (1.0 + scale_bonus)
	
	# Create label
	var label = Label.new()
	if is_critical:
		label.text = str(damage_amount) + "!"
	else:
		label.text = str(damage_amount)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 14 if not is_critical else 20)
	
	# Add outline for better visibility
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	add_child(label)
	
	# Center the label
	label.position = Vector2(-label.size.x / 2, -label.size.y / 2)

func _process(delta):
	lifetime += delta
	
	# Move upward with deceleration
	velocity.y += 200 * delta  # Gravity
	velocity.x *= 0.98  # Horizontal drag
	position += velocity * delta
	
	# Fade out (faster at the end)
	var progress = lifetime / max_lifetime
	if progress > 0.6:
		var fade_progress = (progress - 0.6) / 0.4
		modulate.a = 1.0 - fade_progress
	
	# Scale pop effect at start
	if lifetime < 0.15:
		var t = lifetime / 0.15
		# Elastic pop: overshoot then settle
		var pop = 1.0 + 0.4 * (1.0 - t) * sin(t * PI * 2)
		scale = base_scale * pop
	else:
		scale = base_scale
	
	# Slight shrink at end
	if progress > 0.7:
		var shrink = 1.0 - (progress - 0.7) * 0.5
		scale = base_scale * shrink
	
	if lifetime >= max_lifetime:
		queue_free()

