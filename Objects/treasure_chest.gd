extends Area2D

## Treasure Chest - Spawns after kill thresholds or from bosses
## Now with 3 chest types: Gold, Heal, and Weapon

enum ChestType { GOLD, HEAL, WEAPON }

@export var chest_type: ChestType = ChestType.GOLD
@export var gold_amount: int = 10
@export var heal_amount: int = 25
@export var guaranteed_choices: int = 3  # How many upgrade options

var is_opened := false

# Colors for different chest types
const CHEST_COLORS = {
	ChestType.GOLD: Color(1.0, 0.85, 0.2, 1.0),   # Gold/Yellow
	ChestType.HEAL: Color(0.3, 1.0, 0.4, 1.0),    # Green
	ChestType.WEAPON: Color(0.4, 0.7, 1.0, 1.0),  # Blue
}

@onready var sprite = $Sprite2D
@onready var collision = $CollisionShape2D
@onready var animation_player = $AnimationPlayer
@onready var open_sound = $OpenSound

signal chest_opened(chest)

func _ready():
	add_to_group("treasure")
	
	# Set visual based on chest type
	apply_chest_color()
	
	# Slight spawn animation
	scale = Vector2.ZERO
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2.ONE, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func apply_chest_color():
	if sprite:
		sprite.modulate = CHEST_COLORS[chest_type]

func set_random_type():
	## Called by spawner to randomize chest type with weighted probabilities
	var roll = randf()
	if roll < 0.60:       # 60% Gold
		chest_type = ChestType.GOLD
	elif roll < 0.85:     # 25% Heal
		chest_type = ChestType.HEAL
	else:                 # 15% Weapon
		chest_type = ChestType.WEAPON
	apply_chest_color()

func _on_body_entered(body):
	if body.is_in_group("player") and not is_opened:
		open_chest(body)

func open_chest(player = null):
	if is_opened:
		return
	
	is_opened = true
	collision.set_deferred("disabled", true)
	
	# Play effects
	if animation_player:
		animation_player.play("open")
	if open_sound:
		open_sound.play()
	
	# Apply reward based on chest type
	match chest_type:
		ChestType.GOLD:
			reward_gold()
		ChestType.HEAL:
			reward_heal(player)
		ChestType.WEAPON:
			reward_weapon(player)
	
	# Emit signal for level-up style UI
	emit_signal("chest_opened", self)
	
	# Visual sparkle effect
	spawn_sparkles()
	
	# Queue free after animation
	await get_tree().create_timer(1.0).timeout
	queue_free()

func reward_gold():
	GameManager.add_gold(gold_amount)
	spawn_floating_text("+%d Gold" % gold_amount, CHEST_COLORS[ChestType.GOLD])

func reward_heal(player):
	if player and player.has_method("heal"):
		player.heal(heal_amount)
	elif player:
		# Direct heal if no heal method
		player.hp = min(player.hp + heal_amount, player.maxhp)
		if player.has_node("%HealthBar"):
			player.get_node("%HealthBar").value = player.hp
	spawn_floating_text("+%d HP" % heal_amount, CHEST_COLORS[ChestType.HEAL])

func reward_weapon(player):
	# Give a random weapon upgrade
	if player and player.has_method("levelup"):
		spawn_floating_text("Weapon Upgrade!", CHEST_COLORS[ChestType.WEAPON])
		# Trigger level-up UI
		player.levelup()
	else:
		# Fallback: Give extra gold
		GameManager.add_gold(gold_amount * 2)
		spawn_floating_text("+%d Gold" % (gold_amount * 2), CHEST_COLORS[ChestType.GOLD])

func spawn_floating_text(text: String, color: Color):
	var label = Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	label.global_position = global_position + Vector2(-30, -20)
	get_parent().add_child(label)
	
	var tween = label.create_tween().set_parallel(true)
	tween.tween_property(label, "global_position:y", global_position.y - 50, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.8).set_delay(0.4)
	tween.chain().tween_callback(label.queue_free)

func spawn_sparkles():
	# Create simple particle effect with tweens
	var sparkle_color = CHEST_COLORS[chest_type]
	
	for i in range(8):
		var sparkle = Sprite2D.new()
		sparkle.modulate = sparkle_color
		sparkle.global_position = global_position
		get_parent().add_child(sparkle)
		
		var angle = i * (TAU / 8)
		var target_pos = global_position + Vector2(cos(angle), sin(angle)) * 30
		
		var tween = sparkle.create_tween().set_parallel(true)
		tween.tween_property(sparkle, "global_position", target_pos, 0.5).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tween.tween_property(sparkle, "modulate:a", 0.0, 0.5)
		tween.chain().tween_callback(sparkle.queue_free)
