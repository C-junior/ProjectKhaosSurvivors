extends Area2D

@export var experience = 1

var spr_green = preload("res://Textures/Items/Gems/Gem_green.png")
var spr_blue= preload("res://Textures/Items/Gems/Gem_blue.png")
var spr_red = preload("res://Textures/Items/Gems/Gem_red.png")

var target = null
var speed = -1
var pulse_time := 0.0

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var sound = $snd_collected

func _ready():
	if experience < 5:
		sprite.modulate = Color(0.8, 1.2, 0.8, 1.0)  # Green glow
	elif experience < 25:
		sprite.texture = spr_blue
		sprite.modulate = Color(0.8, 0.9, 1.3, 1.0)  # Blue glow
	else:
		sprite.texture = spr_red
		sprite.modulate = Color(1.3, 0.8, 0.8, 1.0)  # Red glow

func _physics_process(delta):
	if target != null:
		global_position = global_position.move_toward(target.global_position, speed)
		speed += 2*delta
	
	# Pulsing glow effect
	pulse_time += delta * 4.0
	var pulse = 1.0 + sin(pulse_time) * 0.15
	sprite.scale = Vector2.ONE * pulse

func collect():
	sound.play()
	collision.call_deferred("set","disabled",true)
	sprite.visible = false
	return experience


func _on_snd_collected_finished():
	queue_free()
