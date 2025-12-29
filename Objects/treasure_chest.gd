extends Area2D

## Treasure Chest - Spawns after kill thresholds or from bosses
## Contains upgrade choices, gold, and sometimes weapon unlocks

@export var gold_amount: int = 10
@export var guaranteed_choices: int = 3  # How many upgrade options

var is_opened := false

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var animation_player = $AnimationPlayer
@onready var open_sound = $OpenSound

signal chest_opened(chest)

func _ready():
	add_to_group("treasure")
	# Slight spawn animation
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _on_body_entered(body):
	if body.is_in_group("player") and not is_opened:
		open_chest()

func open_chest():
	if is_opened:
		return
	
	is_opened = true
	collision.set_deferred("disabled", true)
	
	# Play effects
	if animation_player:
		animation_player.play("open")
	if open_sound:
		open_sound.play()
	
	# Give gold
	GameManager.add_gold(gold_amount)
	
	# Emit signal for level-up style UI
	emit_signal("chest_opened", self)
	
	# Visual sparkle effect
	spawn_sparkles()
	
	# Queue free after animation
	await get_tree().create_timer(1.0).timeout
	queue_free()

func spawn_sparkles():
	# Create simple particle effect with tweens
	for i in range(8):
		var sparkle = Sprite2D.new()
		# Use a simple visual (will be replaced with actual texture)
		sparkle.modulate = Color(1, 0.9, 0.3, 1)  # Gold color
		sparkle.global_position = global_position
		get_parent().add_child(sparkle)
		
		var angle = i * (TAU / 8)
		var target_pos = global_position + Vector2(cos(angle), sin(angle)) * 30
		
		var tween = sparkle.create_tween().set_parallel(true)
		tween.tween_property(sparkle, "global_position", target_pos, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(sparkle, "modulate:a", 0.0, 0.5)
		tween.chain().tween_callback(sparkle.queue_free)
