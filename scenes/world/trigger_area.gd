extends Area2D

@onready var pressure_button: StaticBody2D = $'..'
@onready var animation_player: AnimationPlayer = $'../AnimationPlayer'

var colliding_objects: Array[Node2D]

func _ready() -> void:
	collision_mask = pressure_button.interactable_entities

func _on_body_entered(body: Node2D) -> void:

	if body is Block or body is Player:
		colliding_objects = get_overlapping_bodies()

	if !pressure_button.turned_on and !colliding_objects.is_empty():
		animation_player.play("press", -1, 1)
		AudioManager.create_audio(SoundEffectSettings.SoundEffectType.BUTTON_PRESS)
		pressure_button.turned_on = true
		_trigger_mechanism(true)


func _on_body_exited(body: Node2D) -> void:
	if body is Block or body is Player:
		colliding_objects = get_overlapping_bodies()
	colliding_objects.erase(body)

	if colliding_objects.is_empty():
		animation_player.play("press", -1, -1, true)
		pressure_button.turned_on = false
		_trigger_mechanism(false)

func _trigger_mechanism(state: bool = false) -> void:
		for connector: LogicElement in pressure_button.connectors:
			if connector is LogicGate:
				connector.gate_on() if state else connector.gate_off()
