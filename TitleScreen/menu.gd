extends Control

var level = "res://World/world.tscn"
var character_select = "res://TitleScreen/character_select.tscn"
var shop = "res://TitleScreen/shop.tscn"

@onready var settings_menu = $SettingsMenu

func _on_btn_play_click_end():
	# Go to character selection first
	var _level = get_tree().change_scene_to_file(character_select)

func _on_btn_quick_play_click_end():
	# Skip character select - quick start with default mage
	if GameManager:
		GameManager.start_new_run("mage")
		GameManager.current_run.weapons.append("icespear1")
	var _level = get_tree().change_scene_to_file(level)

func _on_btn_shop_click_end():
	# Open upgrade shop
	var _level = get_tree().change_scene_to_file(shop)

func _on_btn_settings_click_end():
	# Open settings menu
	if settings_menu:
		settings_menu.show_settings()

func _on_btn_exit_click_end():
	get_tree().quit()
