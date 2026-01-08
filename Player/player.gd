extends CharacterBody2D


var movement_speed = 40.0
var hp = 80
var maxhp = 80
var last_movement = Vector2.UP
var time = 0

var experience = 0
var experience_level = 1
var collected_experience = 0

#Attacks
var iceSpear = preload("res://Player/Attack/ice_spear.tscn")
var tornado = preload("res://Player/Attack/tornado.tscn")
var javelin = preload("res://Player/Attack/javelin.tscn")
var holyCross = preload("res://Player/Attack/holy_cross.tscn")
var fireRing = preload("res://Player/Attack/fire_ring.tscn")
var lightning = preload("res://Player/Attack/lightning.tscn")
var magicMissile = preload("res://Player/Attack/magic_missile.tscn")

#Evolved Attacks
var divineWrath = preload("res://Player/Attack/divine_wrath.tscn")
var infernoAura = preload("res://Player/Attack/inferno_aura.tscn")
var stormCaller = preload("res://Player/Attack/storm_caller.tscn")
var arcaneBarrage = preload("res://Player/Attack/arcane_barrage.tscn")
var frostNova = preload("res://Player/Attack/frost_nova.tscn")
var maelstrom = preload("res://Player/Attack/maelstrom.tscn")

# Evolution flags
var holycross_evolved := false
var firering_evolved := false
var lightning_evolved := false
var magicmissile_evolved := false
var icespear_evolved := false
var tornado_evolved := false

#AttackNodes
@onready var iceSpearTimer = get_node("%IceSpearTimer")
@onready var iceSpearAttackTimer = get_node("%IceSpearAttackTimer")
@onready var tornadoTimer = get_node("%TornadoTimer")
@onready var tornadoAttackTimer = get_node("%TornadoAttackTimer")
@onready var javelinBase = get_node("%JavelinBase")

#UPGRADES
var collected_upgrades = []
var upgrade_options = []
var armor = 0
var speed = 0

# Weapon slot limit
const MAX_WEAPON_SLOTS = 6
var spell_cooldown = 0
var spell_size = 0
var additional_attacks = 0

# New passives
var pickup_radius = 1.0
var luck = 0.0
var xp_multiplier = 1.0
var duplicator_bonus = 0
var damage_bonus = 0.0  # +15% per level from Ring of Power
var regen = 0.0

# New Build-Defining Passives
var blood_pact_active := false
var blood_pact_damage_mult := 0.0

var overcharge_level := 0
var overcharge_cooldown_buff := 0.0
var overcharge_timer := 0.0

var arcane_echo_level := 0
var arcane_echo_proc_chance := 0.0

var second_wind_active := false
var second_wind_used := false
var second_wind_cooldown := 0.0
var second_wind_resist_timer := 0.0
var second_wind_resist_active := false

#IceSpear
var icespear_ammo = 0
var icespear_baseammo = 0
var icespear_attackspeed = 1.5
var icespear_level = 0

#Tornado
var tornado_ammo = 0
var tornado_baseammo = 0
var tornado_attackspeed = 3
var tornado_level = 0

#Javelin
var javelin_ammo = 0
var javelin_level = 0

#HolyCross
var holycross_level = 0
var holycross_attackspeed = 2.0

#FireRing
var firering_level = 0
var firering_count = 0

#Lightning
var lightning_level = 0
var lightning_attackspeed = 2.5

#MagicMissile
var magicmissile_level = 0
var magicmissile_attackspeed = 1.8
var _magicmissile_timer := 0.0

#Enemy Related
var enemy_close = []

# Dash ability
var can_dash := true
var is_dashing := false
var dash_speed := 300.0
var dash_duration := 0.15
var dash_cooldown := 3.0
var dash_timer := 0.0
var dash_direction := Vector2.ZERO


@onready var sprite = $Sprite2D
@onready var walkTimer = get_node("%walkTimer")

#GUI
@onready var expBar = get_node("%ExperienceBar")
@onready var lblLevel = get_node("%lbl_level")
@onready var levelPanel = get_node("%LevelUp")
@onready var upgradeOptions = get_node("%UpgradeOptions")
@onready var itemOptions = preload("res://Utility/item_option.tscn")
@onready var sndLevelUp = get_node("%snd_levelup")
@onready var healthBar = get_node("%HealthBar")
@onready var lblTimer = get_node("%lblTimer")
@onready var collectedWeapons = get_node("%CollectedWeapons")
@onready var collectedUpgrades = get_node("%CollectedUpgrades")
@onready var itemContainer = preload("res://Player/GUI/item_container.tscn")

@onready var deathPanel = get_node("%DeathPanel")
@onready var lblResult = get_node("%lbl_Result")
@onready var sndVictory = get_node("%snd_victory")
@onready var sndLose = get_node("%snd_lose")
@onready var runSummary = $RunSummary

# HUD labels for essence/gold
@onready var essenceLabel = get_node_or_null("%EssenceLabel")
@onready var goldLabel = get_node_or_null("%GoldLabel")
@onready var buffIndicator = get_node_or_null("%BuffIndicator")

# Evolution popup (loaded dynamically)
var evolution_popup_scene = preload("res://Player/GUI/evolution_popup.tscn")
var evolution_popup: CanvasLayer = null

# Buff indicator helper
var BuffIndicatorScript = preload("res://Player/GUI/buff_indicator.gd")

#Signal
signal playerdeath

func _ready():
	# Apply persistent upgrades from GameManager
	apply_persistent_upgrades()
	
	# Load character sprite from GameManager
	if GameManager and GameManager.current_run.sprite != "":
		var sprite_texture = load(GameManager.current_run.sprite)
		if sprite_texture:
			sprite.texture = sprite_texture
	
	# Connect to GameManager signals for HUD updates
	if GameManager:
		GameManager.gold_collected.connect(_on_gold_collected)
		GameManager.essence_collected.connect(_on_essence_collected)
		GameManager.enemy_killed.connect(_on_game_manager_enemy_killed)
	
	# Initialize HUD
	update_resource_hud()
	
	# Create evolution popup instance
	evolution_popup = evolution_popup_scene.instantiate()
	add_child(evolution_popup)
	evolution_popup.evolution_selected.connect(_on_evolution_selected)
	
	# Apply character starting weapon from GameManager or default
	var starting_weapon = "icespear1"
	if GameManager and GameManager.current_run.weapons.size() > 0:
		starting_weapon = GameManager.current_run.weapons[0]
	
	upgrade_character(starting_weapon)
	attack()
	set_expbar(experience, calculate_experiencecap())
	_on_hurt_box_hurt(0,0,0)

func apply_persistent_upgrades():
	if not GameManager:
		return
	
	var upgrades = GameManager.persistent_data.permanent_upgrades
	
	# Apply permanent stat bonuses
	if upgrades.has("max_hp"):
		var bonus = upgrades.max_hp * 10
		maxhp += bonus
		hp = maxhp
	
	if upgrades.has("movement_speed"):
		movement_speed += upgrades.movement_speed * 2  # 2 speed per level
	
	if upgrades.has("pickup_radius"):
		pickup_radius += upgrades.pickup_radius * 0.2
	
	if upgrades.has("xp_gain"):
		xp_multiplier += upgrades.xp_gain * 0.1
	
	if upgrades.has("armor"):
		armor += upgrades.armor
	
	if upgrades.has("luck"):
		luck += upgrades.luck * 0.05

func _physics_process(delta):
	# Handle dash cooldown
	if not can_dash:
		dash_timer -= delta
		if dash_timer <= 0:
			can_dash = true
			# Visual feedback that dash is ready
			modulate = Color(1.1, 1.1, 1.2, 1.0)
			var tween = create_tween()
			tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	# Check for dash input
	if Input.is_action_just_pressed("dash") and can_dash and not is_dashing:
		start_dash()
	
	# Handle dash movement
	if is_dashing:
		velocity = dash_direction * dash_speed
		move_and_slide()
	else:
		movement()
	
	# Regeneration
	if regen > 0 and hp < maxhp:
		hp += regen * delta
		hp = clamp(hp, 0, maxhp)
		healthBar.value = hp
	
	# Overcharge cooldown buff decay
	if overcharge_timer > 0:
		overcharge_timer -= delta
		if overcharge_timer <= 0:
			overcharge_cooldown_buff = 0.0
			remove_buff_indicator("overcharge")
	
	# Update buff indicator timers
	_update_buff_timers(delta)
	
	# Second Wind cooldown
	if second_wind_used and second_wind_cooldown > 0:
		second_wind_cooldown -= delta
		if second_wind_cooldown <= 0:
			second_wind_used = false
	
	# Second Wind resist timer
	if second_wind_resist_active:
		second_wind_resist_timer -= delta
		if second_wind_resist_timer <= 0:
			second_wind_resist_active = false
	
	# New weapons update every frame
	if holycross_level > 0:
		update_holycross(delta)
	if firering_level > 0:
		update_firering()
	if lightning_level > 0:
		update_lightning(delta)
	if magicmissile_level > 0:
		update_magicmissile(delta)

func start_dash():
	is_dashing = true
	can_dash = false
	dash_timer = dash_cooldown
	
	# Dash in last movement direction or facing direction
	var x_mov = Input.get_action_strength("right") - Input.get_action_strength("left")
	var y_mov = Input.get_action_strength("down") - Input.get_action_strength("up")
	var input_dir = Vector2(x_mov, y_mov)
	
	if input_dir != Vector2.ZERO:
		dash_direction = input_dir.normalized()
	else:
		dash_direction = last_movement.normalized()
	
	# Disable collision with enemies during dash (pass through them)
	var hurtbox = get_node_or_null("HurtBox")
	if hurtbox:
		hurtbox.set_deferred("monitoring", false)
		hurtbox.set_deferred("monitorable", false)
	
	# Also disable player's main collision temporarily for phasing
	var main_collision = get_node_or_null("CollisionShape2D")
	if main_collision:
		main_collision.set_deferred("disabled", true)
	
	# Visual effect - ghost trail with phasing color
	modulate = Color(0.5, 0.8, 1.5, 0.6)  # More transparent and blue for phasing
	
	# Spawn trail sprites
	for i in range(5):  # More trails for longer dash visual
		await get_tree().create_timer(dash_duration / 5.0).timeout
		var trail = Sprite2D.new()
		trail.texture = sprite.texture
		trail.hframes = sprite.hframes
		trail.frame = sprite.frame
		trail.flip_h = sprite.flip_h
		trail.scale = sprite.scale
		trail.global_position = global_position
		trail.modulate = Color(0.3, 0.6, 1.0, 0.5)
		get_parent().add_child(trail)
		
		# Fade out trail
		var tween = trail.create_tween()
		tween.tween_property(trail, "modulate:a", 0.0, 0.25)
		tween.tween_callback(trail.queue_free)
	
	# End dash - re-enable collisions
	is_dashing = false
	modulate = Color.WHITE
	
	if hurtbox:
		hurtbox.set_deferred("monitoring", true)
		hurtbox.set_deferred("monitorable", true)
	if main_collision:
		main_collision.set_deferred("disabled", false)

func movement():
	var x_mov = Input.get_action_strength("right") - Input.get_action_strength("left")
	var y_mov = Input.get_action_strength("down") - Input.get_action_strength("up")
	var mov = Vector2(x_mov,y_mov)
	if mov.x > 0:
		sprite.flip_h = false
	elif mov.x < 0:
		sprite.flip_h = true

	if mov != Vector2.ZERO:
		last_movement = mov
		if walkTimer.is_stopped():
			if sprite.frame >= sprite.hframes - 1:
				sprite.frame = 0
			else:
				sprite.frame += 1
			walkTimer.start()
	
	velocity = mov.normalized()*movement_speed
	move_and_slide()

func attack():
	if icespear_level > 0:
		iceSpearTimer.wait_time = icespear_attackspeed * (1-spell_cooldown)
		if iceSpearTimer.is_stopped():
			iceSpearTimer.start()
	if tornado_level > 0:
		tornadoTimer.wait_time = tornado_attackspeed * (1-spell_cooldown)
		if tornadoTimer.is_stopped():
			tornadoTimer.start()
	if javelin_level > 0:
		spawn_javelin()
	# Holy Cross, Fire Ring, and Lightning are updated in _physics_process

func _on_hurt_box_hurt(damage, _angle, _knockback):
	# Invincible during dash
	if is_dashing:
		return
	
	var actual_damage = clamp(damage-armor, 1.0, 999.0)
	
	# Apply Second Wind damage resistance if active
	if second_wind_resist_active:
		actual_damage *= 0.8  # 20% damage reduction
	
	hp -= actual_damage
	healthBar.max_value = maxhp
	healthBar.value = hp
	
	# Screen shake on damage - intensity based on damage
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		var shake_intensity = clamp(actual_damage * 1.5, 3.0, 10.0)
		camera.shake(shake_intensity, 0.8)
	
	# Flash darker red/purple on damage - distinct from attack effects
	modulate = Color(1.0, 0.3, 0.4, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.2)
	
	# Second Wind trigger check
	if second_wind_active and not second_wind_used:
		var hp_threshold = maxhp * 0.25
		if hp <= hp_threshold and hp > 0:
			trigger_second_wind()
	
	if hp <= 0:
		death()

func _on_ice_spear_timer_timeout():
	icespear_ammo += icespear_baseammo + additional_attacks
	iceSpearAttackTimer.start()


func _on_ice_spear_attack_timer_timeout():
	if icespear_ammo > 0:
		var icespear_attack
		# Use evolved version if applicable
		if icespear_evolved:
			icespear_attack = frostNova.instantiate()
		else:
			icespear_attack = iceSpear.instantiate()
			icespear_attack.level = icespear_level
		icespear_attack.position = position
		icespear_attack.target = get_random_target()
		add_child(icespear_attack)
		icespear_ammo -= 1
		if icespear_ammo > 0:
			iceSpearAttackTimer.start()
		else:
			iceSpearAttackTimer.stop()

func _on_tornado_timer_timeout():
	tornado_ammo += tornado_baseammo + additional_attacks
	tornadoAttackTimer.start()

func _on_tornado_attack_timer_timeout():
	if tornado_ammo > 0:
		var tornado_attack
		# Use evolved version if applicable
		if tornado_evolved:
			tornado_attack = maelstrom.instantiate()
		else:
			tornado_attack = tornado.instantiate()
			tornado_attack.level = tornado_level
		tornado_attack.position = position
		tornado_attack.last_movement = last_movement
		add_child(tornado_attack)
		tornado_ammo -= 1
		if tornado_ammo > 0:
			tornadoAttackTimer.start()
		else:
			tornadoAttackTimer.stop()

func spawn_javelin():
	var get_javelin_total = javelinBase.get_child_count()
	var calc_spawns = (javelin_ammo + additional_attacks) - get_javelin_total
	while calc_spawns > 0:
		var javelin_spawn = javelin.instantiate()
		javelin_spawn.global_position = global_position
		javelinBase.add_child(javelin_spawn)
		calc_spawns -= 1
	#Upgrade Javelin
	var get_javelins = javelinBase.get_children()
	for i in get_javelins:
		if i.has_method("update_javelin"):
			i.update_javelin()

# Track timers for new weapons
var _holycross_timer := 0.0
var _lightning_timer := 0.0
var _firering_spawned := false

func update_holycross(delta: float):
	_holycross_timer += delta
	if _holycross_timer >= holycross_attackspeed * (1-spell_cooldown):
		_holycross_timer = 0.0
		var count = 1 + additional_attacks
		for i in range(count):
			var cross
			# Use evolved version if applicable
			if holycross_evolved:
				cross = divineWrath.instantiate()
			else:
				cross = holyCross.instantiate()
			cross.global_position = global_position
			# Get target - if no enemies, use a random direction
			var target_pos = get_random_target()
			if target_pos == Vector2.UP:
				# No enemies - pick random direction at max distance
				target_pos = global_position + Vector2.RIGHT.rotated(randf() * TAU) * 300
			cross.target = target_pos
			cross.level = holycross_level
			get_tree().current_scene.add_child(cross)  # Add to scene, not player

func update_firering():
	# Get target ring count (base + additional attacks)
	var target_count = firering_count + additional_attacks
	
	# Get current fire rings
	var current_rings = []
	for child in get_children():
		if child.is_in_group("attack") and child.has_method("update_fire_ring"):
			current_rings.append(child)
	
	var current_count = current_rings.size()
	
	# Spawn more rings if needed
	while current_count < target_count:
		var ring
		if firering_evolved:
			ring = infernoAura.instantiate()
		else:
			ring = fireRing.instantiate()
		ring.global_position = global_position
		if not firering_evolved:
			ring.level = firering_level
		ring.orbit_index = current_count  # Set index for angle offset
		add_child(ring)
		current_count += 1
	
	# Note: Existing rings handle their own rotation/update via _physics_process

func update_lightning(delta: float):
	_lightning_timer += delta
	if _lightning_timer >= lightning_attackspeed * (1-spell_cooldown):
		_lightning_timer = 0.0
		if enemy_close.size() > 0:
			var count = 1 + additional_attacks
			for i in range(count):
				var bolt
				# Use evolved version if applicable
				if lightning_evolved:
					bolt = stormCaller.instantiate()
				else:
					bolt = lightning.instantiate()
				bolt.global_position = global_position
				bolt.current_target = enemy_close.pick_random()
				if not lightning_evolved:
					bolt.level = lightning_level
				add_child(bolt)

func get_random_target():
	if enemy_close.size() > 0:
		return enemy_close.pick_random().global_position
	else:
		return Vector2.UP

func update_magicmissile(delta: float):
	_magicmissile_timer += delta
	if _magicmissile_timer >= magicmissile_attackspeed * (1-spell_cooldown):
		_magicmissile_timer = 0.0
		if enemy_close.size() > 0:
			# Number of missiles based on level
			# Number of missiles based on level (evolved fires more)
			var missile_count = magicmissile_level + additional_attacks
			if magicmissile_evolved:
				missile_count += 4  # 8 missiles total at evolved
			for i in range(missile_count):
				var missile
				if magicmissile_evolved:
					missile = arcaneBarrage.instantiate()
				else:
					missile = magicMissile.instantiate()
					missile.level = magicmissile_level
				missile.global_position = global_position
				get_tree().current_scene.add_child(missile)


func _on_enemy_detection_area_body_entered(body):
	if not enemy_close.has(body):
		enemy_close.append(body)

func _on_enemy_detection_area_body_exited(body):
	if enemy_close.has(body):
		enemy_close.erase(body)


func _on_grab_area_area_entered(area):
	if area.is_in_group("loot"):
		area.target = self

func _on_collect_area_area_entered(area):
	if area.is_in_group("loot"):
		var gem_exp = area.collect()
		calculate_experience(gem_exp)

func calculate_experience(gem_exp):
	var exp_required = calculate_experiencecap()
	collected_experience += gem_exp
	if experience + collected_experience >= exp_required: #level up
		collected_experience -= exp_required-experience
		experience_level += 1
		experience = 0
		exp_required = calculate_experiencecap()
		levelup()
	else:
		experience += collected_experience
		collected_experience = 0
	
	set_expbar(experience, exp_required)

func calculate_experiencecap():
	var exp_cap = experience_level
	if experience_level < 20:
		exp_cap = experience_level*5
	elif experience_level < 40:
		exp_cap = 95 + (experience_level-19)*8
	else:
		exp_cap = 255 + (experience_level-39)*12
		
	return exp_cap
		
func set_expbar(set_value = 1, set_max_value = 100):
	expBar.value = set_value
	expBar.max_value = set_max_value

func levelup():
	sndLevelUp.play()
	lblLevel.text = str("Level: ",experience_level)
	
	# Level-up visual effects
	# Screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(4.0, 0.3)
	
	# Golden glow effect
	modulate = Color(1.5, 1.4, 0.8, 1.0)
	var glow_tween = create_tween()
	glow_tween.tween_property(self, "modulate", Color.WHITE, 0.5)
	
	# Spawn level-up particles
	ParticleFactory.spawn_hit_particles(get_parent(), global_position, 12, Color(1.0, 0.9, 0.3))
	
	var tween = levelPanel.create_tween()
	tween.tween_property(levelPanel,"position",Vector2(220,50),0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.play()
	levelPanel.visible = true
	var options = 0
	var optionsmax = 3
	while options < optionsmax:
		var option_choice = itemOptions.instantiate()
		option_choice.item = get_random_item()
		upgradeOptions.add_child(option_choice)
		options += 1
	get_tree().paused = true

func upgrade_character(upgrade):
	match upgrade:
		"icespear1":
			icespear_level = 1
			icespear_baseammo += 1
		"icespear2":
			icespear_level = 2
			icespear_baseammo += 1
		"icespear3":
			icespear_level = 3
		"icespear4":
			icespear_level = 4
			icespear_baseammo += 2
		"tornado1":
			tornado_level = 1
			tornado_baseammo += 1
		"tornado2":
			tornado_level = 2
			tornado_baseammo += 1
		"tornado3":
			tornado_level = 3
			tornado_attackspeed -= 0.5
		"tornado4":
			tornado_level = 4
			tornado_baseammo += 1
		"javelin1":
			javelin_level = 1
			javelin_ammo = 1
		"javelin2":
			javelin_level = 2
		"javelin3":
			javelin_level = 3
		"javelin4":
			javelin_level = 4
		"holycross1":
			holycross_level = 1
		"holycross2":
			holycross_level = 2
		"holycross3":
			holycross_level = 3
		"holycross4":
			holycross_level = 4
			holycross_attackspeed -= 0.3
		"firering1":
			firering_level = 1
			firering_count = 1
		"firering2":
			firering_level = 2
		"firering3":
			firering_level = 3
		"firering4":
			firering_level = 4
			firering_count += 1
		"lightning1":
			lightning_level = 1
		"lightning2":
			lightning_level = 2
		"lightning3":
			lightning_level = 3
		"lightning4":
			lightning_level = 4
			lightning_attackspeed -= 0.5
		"magicmissile1":
			magicmissile_level = 1
		"magicmissile2":
			magicmissile_level = 2
			magicmissile_attackspeed -= 0.2
		"magicmissile3":
			magicmissile_level = 3
			magicmissile_attackspeed -= 0.2
		"magicmissile4":
			magicmissile_level = 4
			magicmissile_attackspeed -= 0.3
		"armor1","armor2","armor3","armor4":
			armor += 1
		"speed1","speed2","speed3","speed4":
			movement_speed += 20.0
		"tome1","tome2","tome3","tome4":
			spell_size += 0.10
		"scroll1","scroll2","scroll3","scroll4":
			spell_cooldown += 0.05
		"ring1","ring2","ring3","ring4":
			# Ring of Power gives +15% damage per level
			damage_bonus += 0.15
		"magnet1","magnet2","magnet3","magnet4":
			pickup_radius += 0.30
			# Update grab area scale if it exists
			var grab_area = get_node_or_null("%GrabArea")
			if grab_area:
				grab_area.scale = Vector2.ONE * pickup_radius
		"luck1","luck2","luck3","luck4":
			luck += 0.10
		"crown1","crown2","crown3","crown4":
			xp_multiplier += 0.10
		"duplicator1","duplicator2":
			# Duplicator gives +1 extra projectile per level
			if duplicator_bonus < 2:
				duplicator_bonus += 1
				additional_attacks += 1
		"regen1","regen2","regen3","regen4":
			regen += 0.5
		"food":
			hp += 20
			hp = clamp(hp,0,maxhp)
		# ===== NEW BUILD-DEFINING PASSIVES =====
		"bloodpact1":
			blood_pact_active = true
			blood_pact_damage_mult = 0.25
			# Reduce max HP by 10%
			var hp_loss = maxhp * 0.10
			maxhp -= int(hp_loss)
			hp = min(hp, maxhp)
			damage_bonus += 0.25
			# Show permanent blood pact indicator
			add_buff_indicator("blood_pact", -1)  # -1 = permanent
		"overcharge1":
			overcharge_level = 1
		"overcharge2":
			overcharge_level = 2
		"overcharge3":
			overcharge_level = 3
		"arcaneecho1":
			arcane_echo_level = 1
			arcane_echo_proc_chance = 0.12
		"arcaneecho2":
			arcane_echo_level = 2
			arcane_echo_proc_chance = 0.16
		"arcaneecho3":
			arcane_echo_level = 3
			arcane_echo_proc_chance = 0.20
		"arcaneecho4":
			arcane_echo_level = 4
			arcane_echo_proc_chance = 0.25
		"secondwind1":
			second_wind_active = true
	adjust_gui_collection(upgrade)
	attack()
	var option_children = upgradeOptions.get_children()
	for i in option_children:
		i.queue_free()
	upgrade_options.clear()
	collected_upgrades.append(upgrade)
	
	# Check for weapon evolutions
	check_evolutions()
	
	levelPanel.visible = false
	levelPanel.position = Vector2(800,50)
	get_tree().paused = false
	calculate_experience(0)

func check_evolutions():
	# New choice-based evolution system
	# When a weapon reaches level 4, show the evolution popup with dual-path options
	
	# Holy Cross at level 4 - offer evolution choice
	if not holycross_evolved and holycross_level >= 4:
		if not GameManager or not GameManager.is_weapon_evolved("holycross"):
			show_evolution_popup_for_weapon("holycross", "Holy Cross")
			return  # Only show one evolution at a time
	
	# Fire Ring at level 4 - offer evolution choice
	if not firering_evolved and firering_level >= 4:
		if not GameManager or not GameManager.is_weapon_evolved("firering"):
			show_evolution_popup_for_weapon("firering", "Fire Ring")
			return
	
	# Lightning at level 4 - offer evolution choice
	if not lightning_evolved and lightning_level >= 4:
		if not GameManager or not GameManager.is_weapon_evolved("lightning"):
			show_evolution_popup_for_weapon("lightning", "Lightning")
			return
	
	# Magic Missile at level 4 - offer evolution choice
	if not magicmissile_evolved and magicmissile_level >= 4:
		if not GameManager or not GameManager.is_weapon_evolved("magicmissile"):
			show_evolution_popup_for_weapon("magicmissile", "Magic Missile")
			return
	
	# Ice Spear at level 4 - offer evolution choice
	if not icespear_evolved and icespear_level >= 4:
		if not GameManager or not GameManager.is_weapon_evolved("icespear"):
			show_evolution_popup_for_weapon("icespear", "Ice Spear")
			return
	
	# Tornado at level 4 - offer evolution choice
	if not tornado_evolved and tornado_level >= 4:
		if not GameManager or not GameManager.is_weapon_evolved("tornado"):
			show_evolution_popup_for_weapon("tornado", "Tornado")
			return

func show_evolution_message(weapon_name: String):
	# Display evolution notification
	print("[EVOLUTION] %s unlocked!" % weapon_name)
	
	# Screen shake for epic moment
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(8.0, 1.0)
	
	# Flash gold
	modulate = Color(1.5, 1.3, 0.5, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.5)

# ===== NEW PASSIVE EFFECT FUNCTIONS =====

func trigger_second_wind():
	"""Triggers Second Wind clutch save mechanic."""
	second_wind_used = true
	second_wind_cooldown = 60.0  # 60 second cooldown
	second_wind_resist_active = true
	second_wind_resist_timer = 5.0  # 5 second damage resistance
	
	# Heal 12 HP
	hp += 12
	hp = min(hp, maxhp)
	healthBar.value = hp
	
	# Visual feedback - golden flash
	modulate = Color(1.5, 1.2, 0.5, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)
	
	# Screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(6.0, 0.5)
	
	# Spawn particles
	ParticleFactory.spawn_hit_particles(get_parent(), global_position, 10, Color(1.0, 0.9, 0.4))
	
	# Show buff indicator
	add_buff_indicator("second_wind_resist", 5.0)
	
	print("[Second Wind] Triggered! Healed 12 HP, +20% resist for 5s")

func on_kill_trigger_overcharge():
	"""Called when player kills an enemy to trigger Overcharge cooldown reduction."""
	if overcharge_level <= 0:
		return
	
	# Calculate reduction based on level
	var reduction = 0.08  # 8% base
	match overcharge_level:
		2: reduction = 0.12
		3: reduction = 0.16
	
	# Stack the buff
	overcharge_cooldown_buff += reduction
	overcharge_cooldown_buff = min(overcharge_cooldown_buff, 0.50)  # Cap at 50%
	
	# Reset timer
	var duration = 3.0
	if overcharge_level >= 3:
		duration = 4.0
	overcharge_timer = duration
	
	# Show/update buff indicator with stacks
	var stacks = int(overcharge_cooldown_buff / 0.08)
	add_buff_indicator("overcharge", duration, stacks)
	
	# Apply to spell_cooldown temporarily (will decay)
	# The actual application happens in attack speed calculations

func get_effective_cooldown_reduction() -> float:
	"""Returns total cooldown reduction including temporary Overcharge buff."""
	return spell_cooldown + overcharge_cooldown_buff
	
func get_random_item():
	# Count current unique weapons
	var current_weapons = []
	for upgrade in collected_upgrades:
		if UpgradeDb.UPGRADES.has(upgrade) and UpgradeDb.UPGRADES[upgrade]["type"] == "weapon":
			var base_name = upgrade.rstrip("0123456789")
			if not base_name in current_weapons:
				current_weapons.append(base_name)
	var at_weapon_limit = current_weapons.size() >= MAX_WEAPON_SLOTS
	
	var dblist = []
	for i in UpgradeDb.UPGRADES:
		if i in collected_upgrades: #Find already collected upgrades
			pass
		elif i in upgrade_options: #If the upgrade is already an option
			pass
		elif UpgradeDb.UPGRADES[i]["type"] == "item": #Don't pick food
			pass
		elif UpgradeDb.UPGRADES[i]["type"] == "weapon":
			# Check if this is a new weapon or upgrade to existing
			var base_name = i.rstrip("0123456789")
			var is_new_weapon = not base_name in current_weapons
			
			# Block new weapons if at limit
			if at_weapon_limit and is_new_weapon:
				pass  # Skip new weapons
			elif UpgradeDb.UPGRADES[i]["prerequisite"].size() > 0:
				var to_add = true
				for n in UpgradeDb.UPGRADES[i]["prerequisite"]:
					if not n in collected_upgrades:
						to_add = false
				if to_add:
					dblist.append(i)
			else:
				dblist.append(i)
		elif UpgradeDb.UPGRADES[i]["prerequisite"].size() > 0: #Check for PreRequisites
			var to_add = true
			for n in UpgradeDb.UPGRADES[i]["prerequisite"]:
				if not n in collected_upgrades:
					to_add = false
			if to_add:
				dblist.append(i)
		else:
			dblist.append(i)
	if dblist.size() > 0:
		var randomitem = dblist.pick_random()
		upgrade_options.append(randomitem)
		return randomitem
	else:
		return null

func change_time(argtime = 0):
	time = argtime
	var get_m = int(time/60.0)
	var get_s = time % 60
	if get_m < 10:
		get_m = str(0,get_m)
	if get_s < 10:
		get_s = str(0,get_s)
	lblTimer.text = str(get_m,":",get_s)

func adjust_gui_collection(upgrade):
	var get_upgraded_displayname = UpgradeDb.UPGRADES[upgrade]["displayname"]
	var get_type = UpgradeDb.UPGRADES[upgrade]["type"]
	if get_type != "item":
		var get_collected_displaynames = []
		for i in collected_upgrades:
			get_collected_displaynames.append(UpgradeDb.UPGRADES[i]["displayname"])
		if not get_upgraded_displayname in get_collected_displaynames:
			var new_item = itemContainer.instantiate()
			new_item.upgrade = upgrade
			match get_type:
				"weapon":
					collectedWeapons.add_child(new_item)
				"upgrade":
					collectedUpgrades.add_child(new_item)

func death():
	emit_signal("playerdeath")
	get_tree().paused = true
	
	var is_victory = time >= 600
	
	# Play sound
	if is_victory:
		sndVictory.play()
	else:
		sndLose.play()
	
	# Build unique items with their max level
	var items_with_levels = {}
	for upgrade in collected_upgrades:
		if UpgradeDb.UPGRADES.has(upgrade):
			var upgrade_type = UpgradeDb.UPGRADES[upgrade]["type"]
			if upgrade_type == "weapon" or upgrade_type == "upgrade":
				# Extract base name (remove trailing numbers)
				var base_name = upgrade.rstrip("0123456789")
				# Extract level number
				var level_str = upgrade.substr(base_name.length())
				var level = 1
				if level_str.is_valid_int():
					level = level_str.to_int()
				# Keep the highest level for each base item
				if not items_with_levels.has(base_name) or items_with_levels[base_name] < level:
					items_with_levels[base_name] = level
	
	# Calculate total damage dealt from all attacks
	var total_damage = 0
	if GameManager:
		total_damage = GameManager.run_stats.damage_dealt
	
	# Build stats dictionary
	var stats = {
		"time": time,
		"kills": GameManager.run_stats.kills if GameManager else 0,
		"gold": GameManager.run_stats.gold_collected if GameManager else 0,
		"damage_dealt": total_damage,
		"level": experience_level,
		"items_with_levels": items_with_levels
	}
	
	# Show run summary instead of old death panel
	if runSummary:
		runSummary.show_summary(is_victory, stats)
	else:
		# Fallback to old death panel if run summary not found
		deathPanel.visible = true
		var tween = deathPanel.create_tween()
		tween.tween_property(deathPanel,"position",Vector2(220,50),3.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
		tween.play()
		if is_victory:
			lblResult.text = "You Win"
		else:
			lblResult.text = "You Lose"


func _on_btn_menu_click_end():
	get_tree().paused = false
	var _level = get_tree().change_scene_to_file("res://TitleScreen/menu.tscn")

# ===== GameManager Signal Handlers =====

func _on_gold_collected(_amount: int):
	update_resource_hud()

func _on_essence_collected(_amount: int):
	update_resource_hud()
	# Visual feedback for essence drop
	modulate = Color(0.8, 0.6, 1.2, 1.0)
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)

func _on_game_manager_enemy_killed(_enemy_type: String, _position: Vector2):
	# Trigger Overcharge passive on kill
	on_kill_trigger_overcharge()
	
	# Check for Arcane Echo (this is handled in the attack scripts, not here)
	# Just update kill counter

func update_resource_hud():
	"""Updates the gold and essence display in the HUD."""
	if GameManager:
		if goldLabel:
			goldLabel.text = "Gold: %d" % GameManager.get_gold()
		if essenceLabel:
			essenceLabel.text = "Essence: %d" % GameManager.get_essence()

# ===== Evolution System Handlers =====

func _on_evolution_selected(weapon_id: String, evolution_data: Dictionary):
	"""Called when player selects an evolution from the popup."""
	print("[Player] Evolution selected: %s -> %s" % [weapon_id, evolution_data.get("id", "unknown")])
	
	# Spend resources
	var gold_cost = evolution_data.get("cost_gold", 0)
	var essence_cost = evolution_data.get("cost_essence", 0)
	
	if not GameManager.spend_gold(gold_cost):
		print("[Player] Not enough gold!")
		return
	
	if essence_cost > 0 and not GameManager.spend_essence(essence_cost):
		print("[Player] Not enough essence!")
		GameManager.add_gold(gold_cost)  # Refund gold
		return
	
	# Apply evolution based on weapon
	apply_evolution(weapon_id, evolution_data)
	
	# Update HUD
	update_resource_hud()
	
	# Visual feedback
	show_evolution_message(evolution_data.get("display_name", "Evolution"))

func apply_evolution(weapon_id: String, evolution_data: Dictionary):
	"""Applies the selected evolution to the weapon."""
	match weapon_id:
		"firering":
			firering_evolved = true
			_firering_spawned = false
			# Remove old fire rings
			for child in get_children():
				if child.is_in_group("attack") and child.has_method("update_fire_ring"):
					child.queue_free()
		"lightning":
			lightning_evolved = true
		"magicmissile":
			magicmissile_evolved = true
		"icespear":
			icespear_evolved = true
		"tornado":
			tornado_evolved = true
		"javelin":
			# Javelin evolution handled differently
			pass
		"holycross":
			holycross_evolved = true
	
	# Mark as evolved in GameManager
	if GameManager:
		if not weapon_id in GameManager.current_run.evolved_weapons:
			GameManager.current_run.evolved_weapons.append(weapon_id)

func show_evolution_popup_for_weapon(weapon_id: String, weapon_name: String):
	"""Shows the evolution popup for a max-level weapon."""
	if not evolution_popup:
		print("[Player] Evolution popup not found!")
		return
	
	# Load evolution database
	var EvolutionDb = load("res://Data/evolution_db.gd").new()
	
	# Get passive levels for requirement checking
	var passives = {}
	for upgrade in collected_upgrades:
		var base = upgrade.rstrip("0123456789")
		var level_str = upgrade.substr(base.length())
		if level_str.is_valid_int():
			var level = level_str.to_int()
			if not passives.has(base) or passives[base] < level:
				passives[base] = level
	
	# Get available evolutions
	var evolutions = EvolutionDb.get_available_evolutions(
		weapon_id,
		4,  # Max weapon level
		passives,
		GameManager.get_gold() if GameManager else 0,
		GameManager.get_essence() if GameManager else 0
	)
	
	if evolutions.is_empty():
		print("[Player] No evolutions available for %s" % weapon_id)
		return
	
	# Show the popup
	evolution_popup.show_evolution(weapon_id, weapon_name, evolutions)

# ===== Buff Indicator Helpers =====

const BUFF_ICONS = {
	"blood_pact": {"color": Color(0.8, 0.2, 0.2), "label": "BP"},
	"overcharge": {"color": Color(0.2, 0.8, 1.0), "label": "OC"},
	"arcane_echo": {"color": Color(0.6, 0.3, 1.0), "label": "AE"},
	"second_wind": {"color": Color(0.3, 1.0, 0.5), "label": "SW"},
	"second_wind_resist": {"color": Color(1.0, 0.9, 0.3), "label": "⚡"}
}

var active_buffs: Dictionary = {}

func add_buff_indicator(buff_id: String, duration: float = -1, stacks: int = 1):
	"""Add or update a buff indicator in the HUD."""
	if not buffIndicator:
		return
	
	if active_buffs.has(buff_id):
		# Update existing buff
		var buff_data = active_buffs[buff_id]
		buff_data.timer = duration
		buff_data.stacks = stacks
		_update_buff_display(buff_id)
		# Pulse animation
		var tween = create_tween()
		tween.tween_property(buff_data.node, "scale", Vector2(1.2, 1.2), 0.1)
		tween.tween_property(buff_data.node, "scale", Vector2.ONE, 0.1)
	else:
		# Create new buff icon
		var icon = _create_buff_icon(buff_id)
		buffIndicator.add_child(icon)
		active_buffs[buff_id] = {
			"node": icon,
			"timer": duration,
			"stacks": stacks
		}
		# Animate in
		icon.modulate.a = 0
		icon.scale = Vector2(0.5, 0.5)
		var tween = create_tween().set_parallel()
		tween.tween_property(icon, "modulate:a", 1.0, 0.2)
		tween.tween_property(icon, "scale", Vector2.ONE, 0.2).set_trans(Tween.TRANS_BACK)

func remove_buff_indicator(buff_id: String):
	"""Remove a buff indicator from the HUD."""
	if not active_buffs.has(buff_id):
		return
	
	var buff_data = active_buffs[buff_id]
	var icon = buff_data.node
	
	var tween = create_tween().set_parallel()
	tween.tween_property(icon, "modulate:a", 0.0, 0.15)
	tween.tween_property(icon, "scale", Vector2(0.5, 0.5), 0.15)
	tween.chain().tween_callback(icon.queue_free)
	
	active_buffs.erase(buff_id)

func _create_buff_icon(buff_id: String) -> PanelContainer:
	"""Create a visual buff indicator icon."""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(28, 28)
	
	var style = StyleBoxFlat.new()
	style.bg_color = BUFF_ICONS.get(buff_id, {"color": Color.WHITE}).color
	style.bg_color.a = 0.8
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = BUFF_ICONS.get(buff_id, {"color": Color.WHITE}).color
	panel.add_theme_stylebox_override("panel", style)
	
	var label = Label.new()
	label.text = BUFF_ICONS.get(buff_id, {"label": "?"}).label
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	panel.add_child(label)
	
	var stack_label = Label.new()
	stack_label.name = "StackLabel"
	stack_label.text = ""
	stack_label.add_theme_font_size_override("font_size", 9)
	panel.add_child(stack_label)
	
	return panel

func _update_buff_display(buff_id: String):
	"""Update stack count display for a buff."""
	if not active_buffs.has(buff_id):
		return
	
	var buff_data = active_buffs[buff_id]
	var stack_label = buff_data.node.get_node_or_null("StackLabel")
	if stack_label and buff_data.stacks > 1:
		stack_label.text = "x%d" % buff_data.stacks

func _update_buff_timers(delta: float):
	"""Update buff timers and remove expired buffs."""
	var to_remove = []
	
	for buff_id in active_buffs:
		var buff_data = active_buffs[buff_id]
		if buff_data.timer > 0:
			buff_data.timer -= delta
			if buff_data.timer <= 0:
				to_remove.append(buff_id)
	
	for buff_id in to_remove:
		remove_buff_indicator(buff_id)
