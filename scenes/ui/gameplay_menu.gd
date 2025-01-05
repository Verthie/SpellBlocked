extends Control

@onready var buttons: VBoxContainer = $Buttons
@onready var resume_button: ButtonMenu = $Buttons/ResumeButton

var button_array: Array[ButtonMenu]

var arrow_clicked: bool = false
var mouse_on_button: bool = false

var scene_paths: Dictionary = {}

var keyboard_key_triggers: Array[String] = ["ui_left", "ui_right", "ui_up", "ui_down"]

func _ready() -> void:
	#Globals.game_paused = true

	Cursor.hide()
	InterfaceCursor.show()

	InterfaceCursor.layer = 2

	Globals.started_level = false

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

func _process(_delta: float) -> void:
	if keyboard_key_triggers.any(func(action: String) -> bool: return Input.is_action_just_pressed(action)):
		if !arrow_clicked and !mouse_on_button:
			resume_button.grab_focus()
			arrow_clicked = true

	if Input.is_action_just_pressed('quit'):
		InterfaceCursor.layer = 1
		InterfaceCursor.hide()
		Cursor.show()
		EventBus.game_resumed.emit()
		queue_free()

		#Cursor.sprite_2d.visible = false

	#if Cursor.sprite_2d.visible == false and Input.get_last_mouse_velocity().length() > 30:
		#Cursor.sprite_2d.visible = true

func _on_button_pressed(button: ButtonMenu) -> void:
	InterfaceCursor.layer = 1
	if button == $Buttons/RestartButton:
		AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_BACK)
		EventBus.game_restarted.emit()
	elif button == $Buttons/ResumeButton:
		AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_SELECT)
		EventBus.game_resumed.emit()
		InterfaceCursor.hide()
		Cursor.show()
	elif button == $Buttons/SettingsButton:
		AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_SELECT)
		EventBus.gameplay_settings_entered.emit()
	else:
		AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_SELECT)
		if button.scene_to_switch != null:
			if button.transition == TransitionManager.TransitionType.NONE:
				SceneSwitcher.goto_scene(scene_paths[button.name], button.threaded)
			else:
				TransitionManager.layer = 3
				TransitionManager.play_shader_transition(button.transition, true, button.transition_speed)
				await TransitionManager.finished
				if button == $Buttons/ExitButton:
					BgmManager.stop_audio()
					Globals.game_paused = false
					get_tree().paused = false
					AudioManager.remove_all_audio()
				SceneSwitcher.goto_scene(scene_paths[button.name], button.threaded)
				TransitionManager.play_shader_transition(button.transition, false, button.transition_speed, true, 0.3)
	queue_free()

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
