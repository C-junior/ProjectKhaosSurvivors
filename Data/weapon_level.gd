class_name WeaponLevel extends Resource

## Per-level weapon stats

@export var damage: int = 5
@export var speed: float = 100.0
@export var knockback: float = 100.0
@export var hp: int = 1  # Piercing/hits before despawn
@export var size_multiplier: float = 1.0
@export var projectile_bonus: int = 0  # Additional projectiles at this level
@export var cooldown_reduction: float = 0.0  # Percentage reduction

# Optional special effects at this level
@export var description_override: String = ""  # Level-up description
