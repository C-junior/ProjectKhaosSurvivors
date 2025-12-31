extends Area2D

## Frost Nova - Evolved Ice Spear (Ice Spear 4 + Tome 4)
## A powerful ice projectile that explodes into an AoE freeze on hit

var hp = 3
var speed = 120
var damage = 15
var knockback_amount = 150
var attack_size = 1.3
var explosion_radius = 80.0

var target = Vector2.ZERO
var angle = Vector2.ZERO
var trail_timer := 0.0
var has_exploded := false

@onready var player = get_tree().get_first_node_in_group("player")
signal remove_from_array(object)

func _ready():
	add_to_group("attack")
	angle = global_position.direction_to(target)
	rotation = angle.angle() + deg_to_rad(135)
	
	# Apply player spell size bonus
	if player:
		attack_size *= (1 + player.spell_size)
	
	# Scale up animation
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1, 1) * attack_size, 0.5).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)

func _physics_process(delta):
	position += angle * speed * delta
	
	# Frost trail effect - more intense than regular ice spear
	trail_timer += delta
	if trail_timer >= 0.03:
		trail_timer = 0.0
		spawn_frost_trail()

func spawn_frost_trail():
	var trail = Sprite2D.new()
	trail.global_position = global_position
	trail.rotation = rotation
	trail.scale = scale * 0.8
	trail.modulate = Color(0.5, 0.9, 1.0, 0.6)
	get_parent().add_child(trail)
	
	var tween = trail.create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, 0.3)
	tween.tween_callback(trail.queue_free)

func enemy_hit(_charge = 1):
	hp -= 1
	# Spawn ice hit particles
	ParticleFactory.spawn_hit_particles(get_parent(), global_position, 6, Color(0.5, 0.9, 1.0))
	
	if not has_exploded:
		trigger_frost_explosion()
	
	if hp <= 0:
		emit_signal("remove_from_array", self)
		queue_free()

func trigger_frost_explosion():
	has_exploded = true
	
	# Screen shake for impact
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(4.0, 0.5)
	
	# Visual explosion effect
	spawn_explosion_visual()
	
	# Damage all enemies in explosion radius
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= explosion_radius * attack_size:
			if enemy.has_method("_on_hurtbox_hurt"):
				enemy._on_hurtbox_hurt(damage * 0.6, global_position.angle_to_point(enemy.global_position), knockback_amount * 0.5)
			# Apply freeze slow effect
			if enemy.has_method("apply_slow"):
				enemy.apply_slow(0.5, 2.0)  # 50% slow for 2 seconds
	
	# Spawn more particles for the explosion
	ParticleFactory.spawn_hit_particles(get_parent(), global_position, 16, Color(0.4, 0.8, 1.0))

func spawn_explosion_visual():
	# Create expanding frost circle
	var explosion = Sprite2D.new()
	explosion.global_position = global_position
	explosion.scale = Vector2(0.5, 0.5) * attack_size
	explosion.modulate = Color(0.6, 0.9, 1.0, 0.8)
	get_parent().add_child(explosion)
	
	var tween = explosion.create_tween().set_parallel(true)
	tween.tween_property(explosion, "scale", Vector2(3.0, 3.0) * attack_size, 0.4).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_OUT)
	tween.tween_property(explosion, "modulate:a", 0.0, 0.4)
	tween.chain().tween_callback(explosion.queue_free)

func _on_timer_timeout():
	emit_signal("remove_from_array", self)
	queue_free()
