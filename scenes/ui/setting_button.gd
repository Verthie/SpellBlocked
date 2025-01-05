class_name ButtonSetting
extends Button

@export var unpressed_image: Texture2D
@export var pressed_image: Texture2D

func _ready() -> void:
	pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	if toggle_mode:
		icon = pressed_image if button_pressed else unpressed_image
	else:
		icon = pressed_image
		await get_tree().create_timer(0.15).timeout
		icon = unpressed_image
