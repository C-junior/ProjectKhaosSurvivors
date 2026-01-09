extends Node

## GameEvents - Centralized Event Bus for game-wide signal coordination
## This autoload provides a single point for subscribing to and emitting game events
## Reduces coupling between nodes and simplifies signal management

# ===== Combat Events =====
signal enemy_damaged(enemy: Node, damage: float, source: Node)
signal enemy_killed(enemy: Node, killer: Node, position: Vector2)
signal player_damaged(amount: float, source: Node)
signal player_healed(amount: float, source: Node)
signal boss_spawned(boss: Node)
signal boss_defeated(boss: Node)

# ===== Resource Events =====
signal gold_collected(amount: int)
signal essence_collected(amount: int)
signal gold_spent(amount: int)
signal essence_spent(amount: int)
signal experience_gained(amount: int)

# ===== Progression Events =====
signal level_up(new_level: int)
signal weapon_acquired(weapon_id: String)
signal weapon_evolved(weapon_id: String, evolution_id: String)
signal passive_acquired(passive_id: String)
signal run_started(character: String)
signal run_ended(victory: bool, stats: Dictionary)

# ===== POI Events =====
signal poi_spawned(poi: Node, poi_type: String)
signal poi_activated(poi: Node)
signal poi_completed(poi: Node, success: bool)
signal poi_expired(poi: Node)

# ===== Buff/Effect Events =====
signal buff_applied(buff_id: String, duration: float, stacks: int)
signal buff_removed(buff_id: String)
signal buff_stacks_changed(buff_id: String, new_stacks: int)

# ===== UI Events =====
signal evolution_popup_shown(weapon_id: String)
signal evolution_selected(weapon_id: String, evolution_data: Dictionary)
signal pause_toggled(is_paused: bool)

# ===== Game State =====
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)

# Helper functions for common event patterns

func emit_kill(enemy: Node, killer: Node, position: Vector2):
	"""Convenience function for kill events."""
	emit_signal("enemy_killed", enemy, killer, position)

func emit_damage(target: Node, damage: float, source: Node = null):
	"""Convenience function for damage events."""
	if target.is_in_group("player"):
		emit_signal("player_damaged", damage, source)
	elif target.is_in_group("enemy"):
		emit_signal("enemy_damaged", target, damage, source)

func emit_heal(target: Node, amount: float, source: Node = null):
	"""Convenience function for heal events."""
	if target.is_in_group("player"):
		emit_signal("player_healed", amount, source)

func emit_resource_gain(resource_type: String, amount: int):
	"""Convenience function for resource collection."""
	match resource_type:
		"gold": emit_signal("gold_collected", amount)
		"essence": emit_signal("essence_collected", amount)
		"xp", "experience": emit_signal("experience_gained", amount)

func emit_poi_event(event_type: String, poi: Node, extra = null):
	"""Convenience function for POI events."""
	match event_type:
		"spawned": emit_signal("poi_spawned", poi, extra if extra else "unknown")
		"activated": emit_signal("poi_activated", poi)
		"completed": emit_signal("poi_completed", poi, extra if extra else true)
		"expired": emit_signal("poi_expired", poi)
