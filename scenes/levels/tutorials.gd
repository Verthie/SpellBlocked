extends Node

var key_sprite_dictionary: Dictionary

func _ready() -> void:
	var sign_area_array: Array = $'../../../Interactables/Signs/Section1'.get_children()
	for sign_area: EventTriggerArea in sign_area_array:
		if sign_area.node_holder != null:
			print(sign_area.node_holder)
			if sign_area.name.ends_with('a'):
				sign_area.body_entered.connect(_sign_entered.bind(sign_area.node_holder).unbind(1))
			else:
				sign_area.body_exited.connect(_sign_exited.bind(sign_area.node_holder).unbind(1))

	var tut_text_array: Array = $'.'.get_children()
	for node: Node2D in tut_text_array:
		node.show()
		node.modulate = Color('ffffff00')

	key_sprite_dictionary = {KEY_A: $Tut1/AKey, KEY_D: $Tut1/DKey, KEY_W: $Tut2/WKey, KEY_SPACE: $Tut2/SpaceKey, KEY_S: $Tut3/SKey}

func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		if event.keycode in key_sprite_dictionary:
			if event.pressed:
				if event.keycode >= 64 and event.keycode <= 90: # A-Z
					key_sprite_dictionary[event.keycode].frame_coords.x = 2
				if event.keycode >= 32 and event.keycode <= 41: # Spacebar and Other
					key_sprite_dictionary[event.keycode].frame_coords.x = 10

			elif event.is_released():
				if event.keycode >= 64 and event.keycode <= 90:
					key_sprite_dictionary[event.keycode].frame_coords.x = 0
				if event.keycode >= 32 and event.keycode <= 41:
					key_sprite_dictionary[event.keycode].frame_coords.x = 8


func _set_label_transparency(displayed_node: Node2D, transparency_state: bool = true) -> void:
	var color: Color = Color('ffffff00') if transparency_state else Color('ffffff')
	var tween: Tween = displayed_node.create_tween()
	tween.tween_property(displayed_node, 'modulate', color, 0.25)

func _sign_entered(displayed_node: Node) -> void:
	call_deferred("_set_label_transparency", displayed_node, false)

func _sign_exited(displayed_node: Node) -> void:
	call_deferred("_set_label_transparency", displayed_node)
