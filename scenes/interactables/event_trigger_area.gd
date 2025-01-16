@tool
extends Area2D

## Events that allow to trigger different actions (actions 1 & 3, 1 & 2 can be combined)
@export_category("Events")
@export var is_monit: bool = false:
	set(value):
		if value == is_monit : return
		is_monit = value
		is_scene_switch = false
		only_extra_settings = false
		notify_property_list_changed()

@export var is_music_clip_switch: bool = false:
	set(value):
		if value == is_music_clip_switch : return
		is_music_clip_switch = value
		is_checkpoint = false
		only_extra_settings = false
		notify_property_list_changed()

@export var is_checkpoint: bool = false:
	set(value):
		if value == is_checkpoint : return
		is_checkpoint = value
		is_music_clip_switch = false
		only_extra_settings = false
		notify_property_list_changed()

@export var only_extra_settings: bool = false:
	set(value):
		if value == only_extra_settings : return
		only_extra_settings = value
		is_monit = false
		is_scene_switch = false
		is_music_clip_switch = false
		is_checkpoint = false
		notify_property_list_changed()

@export var is_scene_switch: bool = false:
	set(value):
		if value == is_scene_switch : return
		is_scene_switch = value
		is_monit = false
		is_music_clip_switch = false
		is_checkpoint = false
		only_extra_settings = false
		notify_property_list_changed()

# Dynamic export properties
var label_to_display: Label

## The index of a clip to switch to when reaching area
var clip_index: int = 0

## The id of the checkpoint, for each checkpoint in the level this value must be unique
var checkpoint_id: int = 1
## When music is interactive, clip with this index will play when going back to checkpoint, value: -1 => plays the clip that was last played
var clip_index_on_checkpoint: int = -1
## The parameters that are saved when reaching checkpoint
var save_parameters: int = 3

var scene_to_switch: PackedScene

## Triggers on entering the area rather than pressing the interaction button
var trigger_on_area_enter: bool = true
## Frees the area node after triggering
var one_time_trigger: bool = true

# Local properties
var can_interact: bool = false

#func _ready() -> void:
	#test()

#func test() -> void:
	#print( get_script().get_script_property_list())

func _input(event: InputEvent) -> void:
	if event.is_action_pressed('interact') and can_interact:

		if is_monit:
			if !label_to_display.visible:
				label_to_display.show()
			else:
				label_to_display.hide()

		if is_music_clip_switch:
			BgmManager.set_interactive_audioclip(clip_index)

		if is_checkpoint and Globals.previous_checkpoint_id != checkpoint_id:
				EventBus.entered_checkpoint.emit(checkpoint_id, save_parameters, clip_index_on_checkpoint)

		if is_scene_switch and scene_to_switch:
			_enter_next_level(scene_to_switch.resource_path)

		if one_time_trigger and !is_monit and !is_scene_switch:
			queue_free()

@warning_ignore('untyped_declaration')
func _get_property_list():
	if Engine.is_editor_hint():
		var ret: Array = []
		if is_monit:
			ret.append({
			"name": &"label_to_display",
			"type": TYPE_OBJECT,
			"usage": PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE,# | PROPERTY_USAGE_INTERNAL,
			"hint": PROPERTY_HINT_NODE_TYPE,
			"hint_string": "Label"
			 })
			one_time_trigger = false
		if is_music_clip_switch and !is_checkpoint:
			ret.append({
				"name": &"clip_index",
				"type": TYPE_INT,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE,
				"hint_string": "0,100",
				"hint": PROPERTY_HINT_RANGE
			})
		elif is_checkpoint and !is_music_clip_switch:
			ret.append({
				"name": &"checkpoint_id",
				"type": TYPE_INT,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE,
				"hint_string": "1,100",
				"hint": PROPERTY_HINT_RANGE
			})
			ret.append({
				"name": &"clip_index_on_checkpoint",
				"type": TYPE_INT,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE,
				"hint_string": "-1,100",
				"hint": PROPERTY_HINT_RANGE
			})
			ret.append({
				"name": &"save_parameters",
				"type": TYPE_INT,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE,
				"hint_string": "Player Position:1,Music Clip:2,Block Instances:4,Level Block Positions:8",
				"hint": PROPERTY_HINT_FLAGS
			})
		if is_scene_switch:
			ret.append({
				"name": &"scene_to_switch",
				"type": TYPE_OBJECT,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE,
				"hint": PROPERTY_HINT_RESOURCE_TYPE,
				"hint_string": "PackedScene"
			})
		if is_monit or is_scene_switch or is_music_clip_switch or is_checkpoint or only_extra_settings:
			ret.append({
				"name": &"trigger_on_area_enter",
				"type": TYPE_BOOL,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE,
			})
		if is_music_clip_switch or is_checkpoint or only_extra_settings:
			ret.append({
				"name": &"one_time_trigger",
				"type": TYPE_BOOL,
				"usage": PROPERTY_USAGE_STORAGE | PROPERTY_USAGE_EDITOR | PROPERTY_USAGE_SCRIPT_VARIABLE,
			})
		return ret

func _on_body_entered(_body: Node2D) -> void:
	can_interact = true
	if trigger_on_area_enter:
		can_interact = false

		if is_monit and !label_to_display.visible:
			label_to_display.show()

		if is_music_clip_switch:
			BgmManager.triggered_clip_switch.emit(clip_index)

		if is_checkpoint and Globals.previous_checkpoint_id != checkpoint_id:
			EventBus.entered_checkpoint.emit(checkpoint_id, save_parameters, clip_index_on_checkpoint)

		if is_scene_switch and scene_to_switch:
			_enter_next_level(scene_to_switch.resource_path)

		if one_time_trigger and !is_monit and !is_scene_switch:
			queue_free()

	else:
		EventBus.changed_interaction_state.emit(true)

func _on_body_exited(_body: Node2D) -> void:
	can_interact = false
	if trigger_on_area_enter:
		if is_monit and label_to_display.visible:
			label_to_display.hide()
	else:
		EventBus.changed_interaction_state.emit(false)

func _enter_next_level(level_path: String) -> void:
	Globals.switching = true
	Globals.input_enabled = false
	EventBus.level_finished.emit()
	TransitionManager.play_shader_transition(TransitionManager.ShaderTransitionType.CURVED_DIAMONDS, true, 1)
	await TransitionManager.finished
	SceneSwitcher.goto_scene(level_path)
	TransitionManager.play_shader_transition(TransitionManager.ShaderTransitionType.CURVED_DIAMONDS, false, 1, true)
