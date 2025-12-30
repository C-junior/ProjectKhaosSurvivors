extends CharacterBody2D

## Ghost - Phasing enemy that ignores other enemy collision
## Passes through other enemies, makes player feel surrounded

@export var movement_speed = 25.0
@export var hp = 8
@export var knockback_recovery = 8.0
@export var experience = 3
@export var enemy_damage = 2
@export var enemy_type: String = "ghost"
var knockback = Vector2.ZERO
var phase_alpha := 0.6
var phase_time := 0.0

@onready var player = get_tree().get_first_node_in_group("player")
@onready var loot_base = get_tree().get_first_node_in_group("loot")
@onready var sprite = $Sprite2D
@onready var anim = $AnimationPlayer
@onready var snd_hit = $snd_hit
@onready var hitBox = $HitBox

var death_anim = preload("res://Enemy/explosion.tscn")
var exp_gem = preload("res://Objects/experience_gem.tscn")

signal remove_from_array(object)


func _ready():
	add_to_group("enemy")
	anim.play("walk")
	hitBox.damage = enemy_damage
	
	# Semi-transparent purple ghost appearance
	sprite.modulate = Color(0.8, 0.6, 1.0, phase_alpha)
	
	# Disable enemy-to-enemy collision (ghosts phase through)
	collision_mask = 1  # Only collide with player layer

func _physics_process(delta):
	knockback = knockback.move_toward(Vector2.ZERO, knockback_recovery)
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * movement_speed
	velocity += knockback
	move_and_slide()
	
	if direction.x > 0.1:
		sprite.flip_h = true
	elif direction.x < -0.1:
		sprite.flip_h = false
	
	# Floating/phasing animation
	phase_time += delta * 3.0
	var float_offset = sin(phase_time) * 3.0
	sprite.position.y = float_offset
	
	# Pulsing transparency
	var alpha_pulse = phase_alpha + sin(phase_time * 2.0) * 0.15
	sprite.modulate.a = alpha_pulse

func death():
	emit_signal("remove_from_array", self)
	
	if GameManager:
		GameManager.register_kill(enemy_type, global_position, experience)
	
	# Ghost-specific death effect - more particles, purple
	ParticleFactory.spawn_death_particles(get_parent(), global_position, 0.8)
	
	var enemy_death = death_anim.instantiate()
	enemy_death.scale = Vector2(0.7, 0.7)
	enemy_death.modulate = Color(0.8, 0.6, 1.0, 1.0)
	enemy_death.global_position = global_position
	get_parent().call_deferred("add_child", enemy_death)
	
	var new_gem = exp_gem.instantiate()
	new_gem.global_position = global_position
	new_gem.experience = experience
	loot_base.call_deferred("add_child", new_gem)
	queue_free()

func _on_hurt_box_hurt(damage, angle, knockback_amount):
	hp -= damage
	knockback = angle * knockback_amount * 0.5  # Ghosts have less knockback
	
	if GameManager:
		GameManager.run_stats.damage_dealt += damage
	
	ParticleFactory.spawn_hit_particles(get_parent(), global_position, 3)
	
	if hp <= 0:
		death()
	else:
		snd_hit.play()
		# Brief visibility increase on hit
		sprite.modulate.a = 1.0
		var tween = create_tween()
		tween.tween_property(sprite, "modulate:a", phase_alpha, 0.3)
