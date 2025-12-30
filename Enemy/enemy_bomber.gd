extends CharacterBody2D

## Bomber - Explodes on death dealing AOE damage
## High-risk, high-reward enemy that requires careful positioning

@export var movement_speed = 35.0
@export var hp = 12
@export var knockback_recovery = 3.0
@export var experience = 4
@export var enemy_damage = 3
@export var explosion_damage = 5
@export var explosion_radius = 60.0
@export var enemy_type: String = "bomber"
var knockback = Vector2.ZERO
var warning_distance := 80.0  # Distance at which bomber starts glowing

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
	
	# Warning glow when close to player
	var dist_to_player = global_position.distance_to(player.global_position)
	if dist_to_player < warning_distance:
		var intensity = 1.0 - (dist_to_player / warning_distance)
		var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.02) * 0.3
		sprite.modulate = Color(1.0 + intensity * pulse, 0.5 - intensity * 0.3, 0.3, 1.0)
	else:
		sprite.modulate = Color(1.0, 0.6, 0.4, 1.0)  # Orange tint

func death():
	emit_signal("remove_from_array", self)
	
	if GameManager:
		GameManager.register_kill(enemy_type, global_position, experience)
	
	# EXPLOSION! Deal AOE damage
	explode()
	
	var enemy_death = death_anim.instantiate()
	enemy_death.scale = Vector2(1.5, 1.5)  # Bigger explosion
	enemy_death.modulate = Color(1.0, 0.6, 0.2, 1.0)  # Orange
	enemy_death.global_position = global_position
	get_parent().call_deferred("add_child", enemy_death)
	
	var new_gem = exp_gem.instantiate()
	new_gem.global_position = global_position
	new_gem.experience = experience
	loot_base.call_deferred("add_child", new_gem)
	queue_free()

func explode():
	# Big screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(6.0, 0.4)
	
	# Spawn explosion particles
	ParticleFactory.spawn_death_particles(get_parent(), global_position, 2.0)
	
	# Deal damage to player if in range
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist < explosion_radius:
			if player.has_method("_on_hurt_box_hurt"):
				var direction = global_position.direction_to(player.global_position)
				player._on_hurt_box_hurt(explosion_damage, direction, 150)
	
	# Also damage nearby enemies (chain reaction potential!)
	var enemies = get_tree().get_nodes_in_group("enemy")
	for enemy in enemies:
		if enemy == self:
			continue
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist < explosion_radius * 0.5:  # Smaller radius for enemy damage
			if enemy.has_method("_on_hurt_box_hurt"):
				var direction = global_position.direction_to(enemy.global_position)
				enemy._on_hurt_box_hurt(explosion_damage, direction, 100)

func _on_hurt_box_hurt(damage, angle, knockback_amount):
	hp -= damage
	knockback = angle * knockback_amount
	
	if GameManager:
		GameManager.run_stats.damage_dealt += damage
	
	ParticleFactory.spawn_hit_particles(get_parent(), global_position, 4)
	
	if hp <= 0:
		death()
	else:
		snd_hit.play()
