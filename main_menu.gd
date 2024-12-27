extends Control

@onready var buttons: VBoxContainer = $Camera2D/Buttons
@onready var start_button: ButtonMenu = $Camera2D/Buttons/StartButton
@onready var settings_button: ButtonMenu = $Camera2D/Buttons/SettingsButton
@onready var exit_button: ButtonMenu = $Camera2D/Buttons/ExitButton

var arrow_clicked: bool = false

func _ready() -> void:
	EventBus.changed_cursor_type.emit("Select")

	for button: ButtonMenu in buttons.get_children():
		button.mouse_entered.connect(_on_mouse_entered.bind(button))
		button.mouse_exited.connect(_on_mouse_exited.bind(button))

func _process(_delta: float) -> void:
	if !arrow_clicked and (Input.is_action_just_pressed("ui_down") or Input.is_action_just_pressed("ui_up")):
		arrow_clicked = true
		print(arrow_clicked)
		start_button.grab_focus()

func _on_start_button_pressed() -> void:
	SceneSwitcher.goto_scene(start_button.scene_to_switch)

func _on_settings_button_pressed() -> void:
	SceneSwitcher.goto_scene(settings_button.scene_to_switch)

func _on_exit_button_pressed() -> void:
	get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
	get_tree().quit()

func _on_mouse_entered(button_type: ButtonMenu) -> void:
	if button_type.focus_mode == FocusMode.FOCUS_ALL:
		button_type.release_focus()
		arrow_clicked = false
		button_type.focus_mode = FocusMode.FOCUS_CLICK
		print("current focus mode: ", button_type.focus_mode)

func _on_mouse_exited(button_type: ButtonMenu) -> void:
	if button_type.focus_mode == FocusMode.FOCUS_CLICK:
		button_type.focus_mode = FocusMode.FOCUS_ALL
		print("current focus mode: ", button_type.focus_mode)
