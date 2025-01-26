class_name LogicGate
extends LogicElement

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@export var move_by_pixels: int = 10
@export var move_duration: float = 0.5
@export var enable_ease: bool = false
@export var ease_type: Tween.EaseType = Tween.EaseType.EASE_IN

var init_y_position: float
var init_x_position: float

func _ready() -> void:
	init_y_position = position.y
	init_x_position = position.x
	if rotation_degrees == 180:
		move_by_pixels *= -1

func gate_on() -> void:
	animation_player.play("turn_on")
	var tween: Tween = self.create_tween()
	if enable_ease:
		tween.tween_property(self, 'position', Vector2(init_x_position ,init_y_position + move_by_pixels), move_duration).set_trans(Tween.TRANS_SINE).set_ease(ease_type)
	else:
		tween.tween_property(self, 'position', Vector2(init_x_position ,init_y_position + move_by_pixels), move_duration)

func gate_off() -> void:
	animation_player.play_backwards("turn_on")
	var tween: Tween = self.create_tween()
	if enable_ease:
		tween.tween_property(self, 'position', Vector2(init_x_position ,init_y_position), move_duration).set_trans(Tween.TRANS_SINE).set_ease(ease_type)
	else:
		tween.tween_property(self, 'position', Vector2(init_x_position ,init_y_position), move_duration)
