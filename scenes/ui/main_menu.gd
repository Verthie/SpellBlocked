extends Control

@onready var buttons: VBoxContainer = $Buttons
@onready var new_game_button: ButtonMenu = $Buttons/NewGameButton

var button_array: Array[ButtonMenu]

var arrow_clicked: bool = false
var mouse_on_button: bool = false

var scene_paths: Dictionary = {}

func _ready() -> void:
	_load_settings()

	EventBus.changed_cursor_type.emit("Select")
	Cursor.hide()
	InterfaceCursor.show()
	InterfaceCursor.set_cursor_size(6)
	Globals.started_level = false

	SceneSwitcher.fallback_scene_path = scene_file_path # used by settings_menu

	var game_progress_data: Dictionary = SaveDataManager.load_game_progress()

	var save_level_number: int = game_progress_data["level"]

	var save_level_scene_path: String

	if save_level_number > 0:
		save_level_scene_path = 'res://scenes/levels/level_' + str(save_level_number) + '.tscn'
	else:
		save_level_scene_path = 'res://scenes/levels/level_test.tscn'

	for button: ButtonMenu in buttons.get_children():
		button.mouse_entered.connect(_on_mouse_entered.bind(button))
		button.mouse_exited.connect(_on_mouse_exited)
		button.pressed.connect(_on_button_pressed.bind(button))
		button.focus_entered.connect(_on_button_focused)
		button_array.append(button)
		if button.scene_to_switch != null:
			scene_paths[button.name] = button.scene_to_switch.resource_path
			if button.threaded:
				ResourceLoader.load_threaded_request(scene_paths[button.name])
		elif button == $Buttons/ContinueButton:
			scene_paths[button.name] = save_level_scene_path
			if button.threaded:
				ResourceLoader.load_threaded_request(scene_paths[button.name])


func _process(_delta: float) -> void:
	if !TransitionManager.transitioning:
		if !mouse_on_button and (Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("ui_up")):
			if !arrow_clicked:
				new_game_button.grab_focus()
				arrow_clicked = true

		if Input.is_action_just_pressed('quit'):
			get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
			get_tree().quit()

		#Cursor.sprite_2d.visible = false

	#if Cursor.sprite_2d.visible == false and Input.get_last_mouse_velocity().length() > 30:
		#Cursor.sprite_2d.visible = true

func _on_button_pressed(button: ButtonMenu) -> void:
	if !TransitionManager.transitioning:
		if button.name == $Buttons/ExitButton.name:
			get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
			get_tree().quit()
		else:
			AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_SELECT)
			if button.scene_to_switch != null or button == $Buttons/ContinueButton:
				if button.transition == TransitionManager.TransitionType.NONE:
					SceneSwitcher.goto_scene(scene_paths[button.name], button.threaded)
				else:
					TransitionManager.play_shader_transition(button.transition, true, button.transition_speed)
					await TransitionManager.finished
					if button == $Buttons/NewGameButton:
						SaveDataManager.clear_game_progress()
					SceneSwitcher.goto_scene(scene_paths[button.name], button.threaded)
					TransitionManager.play_shader_transition(button.transition, false, button.transition_speed, true, 0.3)
			else:
				pass

func _on_mouse_entered(passed_button: ButtonMenu) -> void:
	mouse_on_button = true
	arrow_clicked = false
	if !passed_button.has_focus():
		AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_FOCUS)
	for button: ButtonMenu in button_array:
		if button.focus_mode == FocusMode.FOCUS_ALL:
			button.release_focus()
			button.focus_mode = FocusMode.FOCUS_CLICK

func _on_mouse_exited() -> void:
	mouse_on_button = false
	for button: ButtonMenu in button_array:
		if button.focus_mode == FocusMode.FOCUS_CLICK:
			button.focus_mode = FocusMode.FOCUS_ALL

func _on_button_focused() -> void:
	if !mouse_on_button:
		AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_FOCUS)

func _load_settings() -> void:
	var video_data: Dictionary = SaveDataManager.load_video_settings()
	var audio_data: Dictionary = SaveDataManager.load_audio_settings()

	if video_data["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_FULLSCREEN)
	if !video_data["fullscreen"]:
		DisplayServer.window_set_mode(DisplayServer.WindowMode.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_BORDERLESS, false)
		DisplayServer.window_set_size(video_data["resolution"])
		var screen_size: Vector2i = DisplayServer.screen_get_size()
		var window_size: Vector2i = DisplayServer.window_get_size()
		DisplayServer.window_set_position(Vector2i((screen_size.x/2) - (window_size.x/2),(screen_size.y/2)-(window_size.y/2)))

	for i in range(AudioServer.bus_count - 1):
		var key_name: String = AudioServer.get_bus_name(i).to_lower() + '_volume'
		AudioServer.set_bus_volume_db(i, audio_data[key_name])
		Globals.volumes[i] = audio_data[key_name]
		if audio_data[key_name] == -25:
			AudioServer.set_bus_mute(i, true)
