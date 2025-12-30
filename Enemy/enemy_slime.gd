extends CharacterBody2D

## Slime - Basic swarm enemy
## Low HP, spawns in groups, basic chase behavior

@export var movement_speed = 30.0
@export var hp = 5
@export var knockback_recovery = 5.0
@export var experience = 1
@export var enemy_damage = 1
@export var enemy_type: String = "slime"
var knockback = Vector2.ZERO

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
	
	# Slight green tint for slime
	sprite.modulate = Color(0.7, 1.0, 0.7, 1.0)

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
	
	# Bouncy animation
	var bounce = 1.0 + sin(Time.get_ticks_msec() * 0.01) * 0.1
	sprite.scale = Vector2(1.0 / bounce, bounce)

func death():
	emit_signal("remove_from_array", self)
	
	if GameManager:
		GameManager.register_kill(enemy_type, global_position, experience)
	
	# Spawn death particles
	ParticleFactory.spawn_death_particles(get_parent(), global_position, 0.5)
	
	var enemy_death = death_anim.instantiate()
	enemy_death.scale = Vector2(0.5, 0.5)
	enemy_death.global_position = global_position
	get_parent().call_deferred("add_child", enemy_death)
	
	var new_gem = exp_gem.instantiate()
	new_gem.global_position = global_position
	new_gem.experience = experience
	loot_base.call_deferred("add_child", new_gem)
	queue_free()

func _on_hurt_box_hurt(damage, angle, knockback_amount):
	hp -= damage
	knockback = angle * knockback_amount
	
	if GameManager:
		GameManager.run_stats.damage_dealt += damage
	
	ParticleFactory.spawn_hit_particles(get_parent(), global_position, 3)
	
	if hp <= 0:
		death()
	else:
		snd_hit.play()
