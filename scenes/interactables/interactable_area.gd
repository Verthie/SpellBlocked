@tool
extends Area2D

@export var is_sign: bool = false:
	set(value):
		if value == is_sign : return
		is_sign = value
		#test()
		notify_property_list_changed()
#
#@export var is_scene_switch: bool = false:
	#set(value):
		#if value == is_scene_switch : return
		#is_scene_switch = value
		#notify_property_list_changed()

# Dynamic export properties
var scene_to_switch: PackedScene
var trigger_on_area_enter: bool = false

# Local properties
var can_interact: bool
var scene_switch_path: String

#func test():
	#print( get_script().get_script_property_list())

func _process(_delta: float) -> void:
	if !is_sign:
		if scene_to_switch:
			scene_switch_path = scene_to_switch.resource_path

	if can_interact and Input.is_action_just_pressed('interact'):
		if !is_sign:
			_enter_next_level()
		else:
			pass #TODO sign display

@warning_ignore('untyped_declaration')
func _get_property_list():
	if Engine.is_editor_hint():
		var ret: Array = []
		if is_sign:
			#set("is_scene_switch", false)
			ret.clear()
			# This is how you add a normal variable, like String (TYPE_STRING), int (TYPE_INT)...etc
		else:
			set("is_sign", false)
			#set("is_scene_switch", true)
			ret.clear()
			ret.append({
				"name": &"scene_to_switch",
				"class_name": &"PackedScene",
				"type": TYPE_OBJECT,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE,
				"hint": PROPERTY_HINT_RESOURCE_TYPE,
				"hint_string": "PackedScene"
			})
			ret.append({
				"name": &"trigger_on_area_enter",
				"type": TYPE_BOOL,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE,
			})
		return ret

func _on_body_entered(_body: Node2D) -> void:
	can_interact = true
	if !is_sign:
		if trigger_on_area_enter:
			Globals.switching = true
			can_interact = false
			_enter_next_level()
			Globals.input_enabled = false
		else:
			EventBus.changed_interaction_state.emit(true)
		return
	EventBus.changed_interaction_state.emit(true)

func _on_body_exited(_body: Node2D) -> void:
	can_interact = false
	if !is_sign:
		if trigger_on_area_enter:
			return
	EventBus.changed_interaction_state.emit(false)

func _enter_next_level() -> void:
	EventBus.level_finished.emit()
	TransitionManager.play_shader_transition(TransitionManager.ShaderTransitionType.CURVED_DIAMONDS, true, 1)
	await TransitionManager.finished
	SceneSwitcher.goto_scene(scene_switch_path)
	TransitionManager.play_shader_transition(TransitionManager.ShaderTransitionType.CURVED_DIAMONDS, false, 1, true)
