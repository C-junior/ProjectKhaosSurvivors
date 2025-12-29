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
var spell_cooldown = 0
var spell_size = 0
var additional_attacks = 0

# New passives
var pickup_radius = 1.0
var luck = 0.0
var xp_multiplier = 1.0
var duplicator_bonus = 0
var regen = 0.0

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


#Enemy Related
var enemy_close = []


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
	movement()
	
	# Regeneration
	if regen > 0 and hp < maxhp:
		hp += regen * delta
		hp = clamp(hp, 0, maxhp)
		healthBar.value = hp
	
	# New weapons update every frame
	if holycross_level > 0:
		update_holycross(delta)
	if firering_level > 0:
		update_firering()
	if lightning_level > 0:
		update_lightning(delta)

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
	hp -= clamp(damage-armor, 1.0, 999.0)
	healthBar.max_value = maxhp
	healthBar.value = hp
	if hp <= 0:
		death()

func _on_ice_spear_timer_timeout():
	icespear_ammo += icespear_baseammo + additional_attacks
	iceSpearAttackTimer.start()


func _on_ice_spear_attack_timer_timeout():
	if icespear_ammo > 0:
		var icespear_attack = iceSpear.instantiate()
		icespear_attack.position = position
		icespear_attack.target = get_random_target()
		icespear_attack.level = icespear_level
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
		var tornado_attack = tornado.instantiate()
		tornado_attack.position = position
		tornado_attack.last_movement = last_movement
		tornado_attack.level = tornado_level
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
			var cross = holyCross.instantiate()
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
	if not _firering_spawned:
		_firering_spawned = true
		# Spawn fire ring(s) that orbit
		var count = firering_count + additional_attacks
		for i in range(count):
			var ring = fireRing.instantiate()
			ring.global_position = global_position
			ring.level = firering_level
			ring.orbit_index = i
			add_child(ring)

func update_lightning(delta: float):
	_lightning_timer += delta
	if _lightning_timer >= lightning_attackspeed * (1-spell_cooldown):
		_lightning_timer = 0.0
		if enemy_close.size() > 0:
			var count = 1 + additional_attacks
			for i in range(count):
				var bolt = lightning.instantiate()
				bolt.global_position = global_position
				bolt.current_target = enemy_close.pick_random()
				bolt.level = lightning_level
				add_child(bolt)

func get_random_target():
	if enemy_close.size() > 0:
		return enemy_close.pick_random().global_position
	else:
		return Vector2.UP


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
		exp_cap + 95 * (experience_level-19)*8
	else:
		exp_cap = 255 + (experience_level-39)*12
		
	return exp_cap
		
func set_expbar(set_value = 1, set_max_value = 100):
	expBar.value = set_value
	expBar.max_value = set_max_value

func levelup():
	sndLevelUp.play()
	lblLevel.text = str("Level: ",experience_level)
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
		"armor1","armor2","armor3","armor4":
			armor += 1
		"speed1","speed2","speed3","speed4":
			movement_speed += 20.0
		"tome1","tome2","tome3","tome4":
			spell_size += 0.10
		"scroll1","scroll2","scroll3","scroll4":
			spell_cooldown += 0.05
		"ring1","ring2","ring3","ring4":
			additional_attacks += 1
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
			duplicator_bonus += 1
			additional_attacks += 1
		"regen1","regen2","regen3","regen4":
			regen += 0.5
		"food":
			hp += 20
			hp = clamp(hp,0,maxhp)
	adjust_gui_collection(upgrade)
	attack()
	var option_children = upgradeOptions.get_children()
	for i in option_children:
		i.queue_free()
	upgrade_options.clear()
	collected_upgrades.append(upgrade)
	levelPanel.visible = false
	levelPanel.position = Vector2(800,50)
	get_tree().paused = false
	calculate_experience(0)
	
func get_random_item():
	var dblist = []
	for i in UpgradeDb.UPGRADES:
		if i in collected_upgrades: #Find already collected upgrades
			pass
		elif i in upgrade_options: #If the upgrade is already an option
			pass
		elif UpgradeDb.UPGRADES[i]["type"] == "item": #Don't pick food
			pass
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
	deathPanel.visible = true
	emit_signal("playerdeath")
	get_tree().paused = true
	var tween = deathPanel.create_tween()
	tween.tween_property(deathPanel,"position",Vector2(220,50),3.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tween.play()
	if time >= 300:
		lblResult.text = "You Win"
		sndVictory.play()
	else:
		lblResult.text = "You Lose"
		sndLose.play()


func _on_btn_menu_click_end():
	get_tree().paused = false
	var _level = get_tree().change_scene_to_file("res://TitleScreen/menu.tscn")
