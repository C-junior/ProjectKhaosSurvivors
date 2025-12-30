extends Area2D

## Divine Wrath - Evolved Holy Cross
## Multiple boomerangs that explode on return, creating holy shockwaves

var level = 5  # Evolution level
var hp = 9999
var speed = 200.0
var damage = 25
var knockback_amount = 120
var attack_size = 1.5
var return_speed_mult = 2.0

var target = Vector2.ZERO
var angle = Vector2.ZERO
var is_returning := false
var max_distance := 400.0
var traveled_distance := 0.0
var spin_speed := 1080.0  # Faster spin
var trail_timer := 0.0

@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite = $Sprite2D

# Trail effect
var trail_positions := []
var max_trail := 8

signal remove_from_array(object)

func _ready():
	# Divine Wrath is always max power
	attack_size = 1.5 * (1 + player.spell_size)
	
	# Initial direction toward target or random
	if target != Vector2.ZERO:
		angle = global_position.direction_to(target)
	else:
		angle = Vector2.RIGHT.rotated(randf() * TAU)
	
	# Epic scale-in animation
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * attack_size, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	
	# Golden glow for evolved weapon
	modulate = Color(1.0, 0.9, 0.5, 1.0)

func _physics_process(delta):
	# Spin the sprite faster
	if sprite:
		sprite.rotation_degrees += spin_speed * delta
	
	# Trail effect
	trail_timer += delta
	if trail_timer > 0.03:
		trail_timer = 0.0
		spawn_trail()
	
	if not is_returning:
		# Move outward
		position += angle * speed * delta
		traveled_distance += speed * delta
		
		# Check if should return
		if traveled_distance >= max_distance:
			is_returning = true
			# Emit holy shockwave at turning point
			spawn_shockwave()
	else:
		# Return to player faster
		var to_player = global_position.direction_to(player.global_position)
		position += to_player * speed * return_speed_mult * delta
		
		# Check if reached player
		if global_position.distance_to(player.global_position) < 30:
			# Explode on return
			spawn_shockwave()
			emit_signal("remove_from_array", self)
			queue_free()

func spawn_trail():
	# Create lingering damage trail
	var trail = Area2D.new()
	trail.global_position = global_position
	trail.collision_layer = 0
	trail.collision_mask = 4  # Enemy layer
	
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 12 * attack_size
	shape.shape = circle
	trail.add_child(shape)
	
	# Visual
	var visual = Sprite2D.new()
	visual.modulate = Color(1.0, 0.9, 0.3, 0.6)
	visual.scale = Vector2.ONE * 0.3 * attack_size
	trail.add_child(visual)
	
	get_parent().add_child(trail)
	
	# Fade and remove
	var tween = trail.create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, 0.3)
	tween.tween_callback(trail.queue_free)

func spawn_shockwave():
	# Create expanding damage ring
	var shockwave = Area2D.new()
	shockwave.global_position = global_position
	shockwave.collision_layer = 0
	shockwave.collision_mask = 4
	
	var shape = CollisionShape2D.new()
	var circle = CircleShape2D.new()
	circle.radius = 50 * attack_size
	shape.shape = circle
	shockwave.add_child(shape)
	
	get_parent().add_child(shockwave)
	
	# Expand and fade
	var tween = shockwave.create_tween()
	tween.set_parallel(true)
	tween.tween_property(shockwave, "scale", Vector2.ONE * 2.0, 0.3)
	tween.tween_property(shockwave, "modulate:a", 0.0, 0.3)
	tween.set_parallel(false)
	tween.tween_callback(shockwave.queue_free)
	
	# Screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(4.0, 0.5)

func enemy_hit(_charge = 1):
	# Divine Wrath pierces everything
	pass

func _on_timer_timeout():
	emit_signal("remove_from_array", self)
	queue_free()
