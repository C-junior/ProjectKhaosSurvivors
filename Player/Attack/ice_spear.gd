extends Area2D

var level = 1
var hp = 1
var speed = 100
var damage = 5
var knockback_amount = 100
var attack_size = 1.0

var target = Vector2.ZERO
var angle = Vector2.ZERO
var trail_timer := 0.0

@onready var player = get_tree().get_first_node_in_group("player")
signal remove_from_array(object)

func _ready():
	add_to_group("attack")
	angle = global_position.direction_to(target)
	rotation = angle.angle() + deg_to_rad(135)
	match level:
		1:
			hp = 1
			speed = 100
			damage = 5
			knockback_amount = 100
			attack_size = 1.0 * (1 + player.spell_size)
		2:
			hp = 1
			speed = 100
			damage = 5
			knockback_amount = 100
			attack_size = 1.0 * (1 + player.spell_size)
		3:
			hp = 2
			speed = 100
			damage = 8
			knockback_amount = 100
			attack_size = 1.0 * (1 + player.spell_size)
		4:
			hp = 2
			speed = 100
			damage = 8
			knockback_amount = 100
			attack_size = 1.0 * (1 + player.spell_size)

	
	var tween = create_tween()
	tween.tween_property(self,"scale",Vector2(1,1)*attack_size,1).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.play()

func _physics_process(delta):
	position += angle*speed*delta
	
	# Ice trail effect
	trail_timer += delta
	if trail_timer >= 0.05:
		trail_timer = 0.0
		spawn_ice_trail()

func spawn_ice_trail():
	var trail = Sprite2D.new()
	trail.global_position = global_position
	trail.rotation = rotation
	trail.scale = scale * 0.7
	trail.modulate = Color(0.6, 0.8, 1.0, 0.5)
	get_parent().add_child(trail)
	
	var tween = trail.create_tween()
	tween.tween_property(trail, "modulate:a", 0.0, 0.2)
	tween.tween_callback(trail.queue_free)

func enemy_hit(charge = 1):
	hp -= charge
	# Spawn ice hit particles
	ParticleFactory.spawn_hit_particles(get_tree().current_scene, global_position, 4, Color(0.5, 0.8, 1.0))
	if hp <= 0:
		emit_signal("remove_from_array",self)
		queue_free()


func _on_timer_timeout():
	emit_signal("remove_from_array",self)
	queue_free()
