extends Camera2D

## Camera with screen shake and smooth follow
## Attach to player or main scene

var shake_amount: float = 0.0
var shake_decay: float = 5.0
var target: Node2D

func _ready():
	# Connect to GameManager events if available
	if GameManager:
		GameManager.enemy_killed.connect(_on_enemy_killed)
		GameManager.boss_spawned.connect(_on_boss_spawned)

func _process(delta):
	# Apply shake
	if shake_amount > 0:
		offset = Vector2(
			randf_range(-shake_amount, shake_amount),
			randf_range(-shake_amount, shake_amount)
		)
		shake_amount = lerp(shake_amount, 0.0, shake_decay * delta)
		if shake_amount < 0.1:
			shake_amount = 0.0
			offset = Vector2.ZERO

func shake(amount: float = 5.0, duration_factor: float = 1.0):
	shake_amount = max(shake_amount, amount)
	shake_decay = 5.0 / duration_factor

func small_shake():
	shake(2.0, 0.5)

func medium_shake():
	shake(5.0, 1.0)

func big_shake():
	shake(10.0, 2.0)

# Event handlers
func _on_enemy_killed(enemy_type: String, _position: Vector2):
	if enemy_type.begins_with("elite"):
		medium_shake()
	elif enemy_type.begins_with("boss"):
		big_shake()

func _on_boss_spawned(_boss_type: String):
	big_shake()
