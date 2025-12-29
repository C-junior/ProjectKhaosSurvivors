extends Node2D

## Floating Damage Numbers - Shows damage dealt to enemies
## Spawn this at enemy position when damage is dealt

@export var damage_amount: int = 0
@export var is_critical: bool = false
@export var color: Color = Color.WHITE

var velocity := Vector2.ZERO
var lifetime := 0.0
var max_lifetime := 0.8

func _ready():
	# Random horizontal offset for variety
	velocity = Vector2(randf_range(-30, 30), -80)
	
	# Style based on damage type
	if is_critical:
		color = Color(1.0, 0.3, 0.1, 1.0)  # Red-orange for crits
		scale = Vector2(1.5, 1.5)
	
	# Create label
	var label = Label.new()
	label.text = str(damage_amount)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 12 if not is_critical else 16)
	add_child(label)
	
	# Center the label
	label.position = Vector2(-label.size.x / 2, -label.size.y / 2)

func _process(delta):
	lifetime += delta
	
	# Move upward with deceleration
	velocity.y += 150 * delta  # Gravity
	position += velocity * delta
	
	# Fade out
	var alpha = 1.0 - (lifetime / max_lifetime)
	modulate.a = alpha
	
	# Scale pop effect
	if lifetime < 0.1:
		var t = lifetime / 0.1
		scale = Vector2.ONE * (1.0 + 0.5 * (1.0 - t))
		if is_critical:
			scale *= 1.5
	
	if lifetime >= max_lifetime:
		queue_free()
