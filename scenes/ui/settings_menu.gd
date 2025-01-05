extends Control

# STYLES
const SETTINGS_BUTTON_FOCUS: StyleBoxFlat = preload('res://resources/ui_themes/settings_button_focus.tres')
const SETTINGS_BUTTON_HOVER_PRESS: StyleBoxFlat = preload('res://resources/ui_themes/settings_button_hover_press.tres')

@export_range(1, 16, 1) var cursor_size: int = 6

@onready var fullscreen_button: ButtonSetting = $MarginContainer/VBoxContainer/Fullscreen/FullscreenButton
@onready var left_resolution: ButtonSetting = $MarginContainer/VBoxContainer/Resolution/HBox/Left
@onready var right_resolution: ButtonSetting = $MarginContainer/VBoxContainer/Resolution/HBox/Right
@onready var volume_left: ButtonVolume = $MarginContainer/VBoxContainer/Volume/HBox/VolumeLeft
@onready var volume_right: ButtonVolume = $MarginContainer/VBoxContainer/Volume/HBox/VolumeRight

var has_previous_scene: bool = false
var previous_scene: String

var resolutions: Array[Vector2i] = [Vector2i(640, 360), Vector2i(960, 540), Vector2i(1280, 720), Vector2i(1600, 900), Vector2i(1920, 1080)]
var resolution_index: int = 2

var volume_sprite_frames: Dictionary = {-25: 0, -20: 1,-15: 2,-10: 3, -5: 4, 0: 5}

var button_array: Array[Button]
var keyboard_key_triggers: Array[String] = ["ui_left", "ui_right", "ui_up", "ui_down"]

var arrow_clicked: bool = false
var mouse_on_button: bool = false

var in_gameplay_settings: bool = false

func _ready() -> void:
	_load_settings()

	EventBus.changed_cursor_type.emit("Select")
	InterfaceCursor.layer = 2
	Globals.started_level = false

	for button: Button in get_tree().get_nodes_in_group("Buttons"):
		button.mouse_entered.connect(_on_mouse_entered.bind(button))
		button.mouse_exited.connect(_on_mouse_exited.bind(button))
		button.pressed.connect(_on_button_pressed.bind(button))
		button.focus_entered.connect(_on_button_focused.bind(button))
		button_array.append(button)

	in_gameplay_settings = false if SceneSwitcher.fallback_scene_path == 'res://scenes/ui/main_menu.tscn' else true

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed('quit'):
		if in_gameplay_settings:
			EventBus.game_paused.emit()
			queue_free()
		else:
			SceneSwitcher.goto_previous_scene()

	if keyboard_key_triggers.any(func(action: String) -> bool: return Input.is_action_just_pressed(action)):
		if !arrow_clicked and !mouse_on_button:
			fullscreen_button.grab_focus()
			fullscreen_button.add_theme_stylebox_override("focus", SETTINGS_BUTTON_FOCUS)
			arrow_clicked = true

func _on_button_pressed(button: Button) -> void:
	if button == $TextButtons/BackButton:
		if in_gameplay_settings:
			EventBus.game_paused.emit()
			queue_free()
		else:
			SceneSwitcher.goto_previous_scene()

	if button == fullscreen_button:
		_toggle_resolution_setting()

	if button is ButtonSetting:
		if (mouse_on_button or arrow_clicked) and button.toggle_mode:
			if button.button_pressed:
				button.add_theme_stylebox_override("focus", SETTINGS_BUTTON_HOVER_PRESS)
			else:
				if !arrow_clicked:
					button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
				else:
					button.add_theme_stylebox_override("focus", SETTINGS_BUTTON_FOCUS)
		if !button.toggle_mode:
			button.add_theme_stylebox_override("focus", SETTINGS_BUTTON_HOVER_PRESS)
			await get_tree().create_timer(0.15).timeout
			button.add_theme_stylebox_override("focus", SETTINGS_BUTTON_FOCUS)
		if button is not ButtonVolume and (button != left_resolution and button != right_resolution):
			if button.button_pressed:
				AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_SELECT, 1.1)
			else:
				AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_SELECT, 0.95)

		if button != fullscreen_button:
			if button == left_resolution:
				AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_SELECT, 0.95)
				resolution_index -= 1
			elif button == right_resolution:
				AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_SELECT, 1.1)
				resolution_index += 1
			resolution_index = clamp(resolution_index, 0, 4)
			_update_resolution_label(resolutions[resolution_index].x, resolutions[resolution_index].y)

	if button is ButtonVolume:
		var bus_index: int = AudioServer.get_bus_index(button.bus)
		if button.left_button:
			AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_SELECT, 0.95)
			if button.volume_bar.frame > 0:
				Globals.update_volume(bus_index, -5)
				button.volume_bar.frame -= 1
			if button.volume_bar.frame == 0:
				AudioServer.set_bus_mute(bus_index, true)
		elif !button.left_button:
			AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_SELECT, 1.1)
			if AudioServer.is_bus_mute(bus_index):
				AudioServer.set_bus_mute(bus_index, false)
			if button.volume_bar.frame < 5:
				Globals.update_volume(bus_index, 5)
				button.volume_bar.frame += 1

	if button is not ButtonSetting:
		AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_SELECT)

func _on_mouse_entered(passed_button: Button) -> void:
	mouse_on_button = true
	arrow_clicked = false
	if !passed_button.button_pressed and passed_button is ButtonSetting:
		passed_button.add_theme_stylebox_override("focus", SETTINGS_BUTTON_FOCUS)
	if !passed_button.has_focus() and !passed_button.is_in_group("Setting_Buttons"):
		AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_FOCUS)
	for button: Button in button_array:
		if button.focus_mode == FocusMode.FOCUS_ALL:
			button.release_focus()
			button.focus_mode = FocusMode.FOCUS_CLICK

func _on_mouse_exited(passed_button: Button) -> void:
	mouse_on_button = false
	if !passed_button.button_pressed and passed_button is ButtonSetting:
		passed_button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	for button: Button in button_array:
		if button.focus_mode == FocusMode.FOCUS_CLICK:
			button.focus_mode = FocusMode.FOCUS_ALL

func _on_button_focused(button: Button) -> void:
	if !mouse_on_button:
		AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_FOCUS)
	if arrow_clicked and button is ButtonSetting:
		button.add_theme_stylebox_override("focus", SETTINGS_BUTTON_FOCUS)

func _load_settings() -> void:
	var video_data: Dictionary = SaveDataManager.load_video_settings()
	var audio_data: Dictionary = SaveDataManager.load_audio_settings()

	if video_data["fullscreen"]:
		fullscreen_button.button_pressed = true
		fullscreen_button._on_button_pressed()
		_toggle_resolution_setting()

	var res: Vector2i = video_data["resolution"]
	var resolution_x_text: String = str(res.x)
	var resolution_y_text: String = str(res.y)
	$MarginContainer/VBoxContainer/Resolution/HBox/OptionLabel.text = resolution_x_text + "x" + resolution_y_text
	resolution_index = resolutions.find(res)

	var master_volume: int = audio_data["master_volume"]
	var music_volume: int = audio_data["music_volume"]
	var sfx_volume: int = audio_data["sfx_volume"]

	#print("volume: ", "[master: ", master_volume, "] [music: ", music_volume, "] [sfx: ", sfx_volume, "]")

	var master_sprite_frame: int = volume_sprite_frames[master_volume]
	var music_sprite_frame: int = volume_sprite_frames[music_volume]
	var sfx_sprite_frame: int = volume_sprite_frames[sfx_volume]

	#print("sprite_frames: ", "[master: ", master_sprite_frame, "] [music: ", music_sprite_frame, "] [sfx: ", sfx_sprite_frame, "]")

	$MarginContainer/VBoxContainer/Volume/HBox/OptionLabel/VolumeBar.frame = master_sprite_frame
	$MarginContainer/VBoxContainer/Music/HBox/OptionLabel/VolumeBar.frame = music_sprite_frame
	$MarginContainer/VBoxContainer/Sfx/HBox/OptionLabel/VolumeBar.frame = sfx_sprite_frame

func _on_apply_button_pressed() -> void:
	SaveDataManager.save_video_setting("fullscreen", fullscreen_button.button_pressed)
	SaveDataManager.save_video_setting("resolution", resolutions[resolution_index])

	if fullscreen_button.button_pressed:
		if DisplayServer.window_get_mode() == DisplayServer.WindowMode.WINDOW_MODE_WINDOWED:
			DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
	if !fullscreen_button.button_pressed:
		if DisplayServer.window_get_mode() == DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_size(resolutions[resolution_index])
		var screen_size: Vector2i = DisplayServer.screen_get_size()
		var window_size: Vector2i = DisplayServer.window_get_size()
		DisplayServer.window_set_position(Vector2i((screen_size.x/2) - (window_size.x/2),(screen_size.y/2)-(window_size.y/2)))

	SaveDataManager.save_audio_setting("master_volume", Globals.volumes[0])
	SaveDataManager.save_audio_setting("music_volume", Globals.volumes[1])
	SaveDataManager.save_audio_setting("sfx_volume", Globals.volumes[2])

func _toggle_resolution_setting() -> void:
	left_resolution.disabled = fullscreen_button.button_pressed
	right_resolution.disabled = fullscreen_button.button_pressed
	$MarginContainer/VBoxContainer/Resolution/HBox/OptionLabel.self_modulate = Color("ffffff3a") if fullscreen_button.button_pressed else Color("ffffff")
	fullscreen_button.focus_neighbor_left = left_resolution.get_path() if !left_resolution.disabled else volume_left.get_path()
	fullscreen_button.focus_neighbor_right = right_resolution.get_path() if !right_resolution.disabled else volume_right.get_path()
	fullscreen_button.focus_neighbor_bottom = left_resolution.get_path() if !left_resolution.disabled else volume_left.get_path()
	$MarginContainer/VBoxContainer/Volume/HBox/VolumeLeft.focus_neighbor_top = fullscreen_button.get_path() if left_resolution.disabled else left_resolution.get_path()
	$MarginContainer/VBoxContainer/Volume/HBox/VolumeRight.focus_neighbor_top = fullscreen_button.get_path()  if left_resolution.disabled else right_resolution.get_path()

func _update_resolution_label(resolution_x: int, resolution_y: int) -> void:
	var resolution_x_text: String = str(resolution_x)
	var resolution_y_text: String = str(resolution_y)
	$MarginContainer/VBoxContainer/Resolution/HBox/OptionLabel.text = resolution_x_text + "x" + resolution_y_text
