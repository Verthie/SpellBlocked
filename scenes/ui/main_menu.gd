extends Control

@onready var buttons: VBoxContainer = $Camera2D/Buttons
@onready var start_button: ButtonMenu = $Camera2D/Buttons/StartButton

var button_array: Array[ButtonMenu]

var arrow_clicked: bool = false
var mouse_on_button: bool = false
#var cursor_hidden: bool = false

var scene_paths: Dictionary = {}

func _ready() -> void:
	EventBus.changed_cursor_type.emit("Select")
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
	if !mouse_on_button and (Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("ui_up")):
		if !arrow_clicked:
			start_button.grab_focus()
			arrow_clicked = true

		#Cursor.sprite_2d.visible = false

	#if Cursor.sprite_2d.visible == false and Input.get_last_mouse_velocity().length() > 30:
		#Cursor.sprite_2d.visible = true

func _on_button_pressed(button: ButtonMenu) -> void:
	if button.name == $Camera2D/Buttons/ExitButton.name:
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
		get_tree().quit()
	else:
		AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_SELECT)
		if button.scene_to_switch != null:
			SceneSwitcher.fallback_scenes.append(SceneSwitcher.current_scene)
			if button.transition == TransitionManager.TransitionType.NONE:
				SceneSwitcher.goto_scene(scene_paths[button.name], button.threaded)
			else:
				await TransitionManager.play_transition(button.transition, false, button.transition_speed)
				SceneSwitcher.goto_scene(scene_paths[button.name], button.threaded)
				TransitionManager.play_transition(button.transition, true, button.transition_speed)
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
