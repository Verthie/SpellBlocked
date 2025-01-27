extends ParentLevel

@onready var hidden_locations: Node2D = $TileMaps/NoCollisionPlanes/ForegroundPlanes/HiddenLocations

var wand_received: bool = false

func _init() -> void:
	EventBus.game_restarted.connect(_set_default_values)

func _input(event: InputEvent) -> void:
	if !Globals.switching and !TransitionManager.transitioning and !Globals.playing_cutscene:
		if event.is_action_pressed('restart') and !wand_received:
			restarted_or_exited.emit('restart')
			AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_BACK)
			call_deferred("_restart", TransitionManager.ShaderTransitionType.CURVED_DIAMONDS, 1)
		elif event.is_action_pressed('quit'):
			if !Globals.game_paused:
				_level_pause()
			else:
				_level_unpause()

func _on_hidden_area_access_body_entered(body: Node2D) -> void:
	if body is Block:
		call_deferred("_enable_hidden_area_access")

func _enable_hidden_area_access() -> void:
	$LevelElements/InvisibleWalls/HiddenAreaAccessEnable/CollisionShape2D.disabled = false
	$LevelElements/InvisibleWalls/HiddenAreaAccessPrevent/CollisionShape2D.disabled = true

func _on_hidden_area_body_entered(_body: Node2D) -> void:
	call_deferred("_set_area_transparency", false)

func _on_hidden_area_body_exited(_body: Node2D) -> void:
	call_deferred("_set_area_transparency")

func _set_area_transparency(transparency_state: bool = true) -> void:
	if hidden_locations == null:
		return
	var color: Color = Color('ffffff00') if transparency_state else Color('ffffffe6')
	var tween: Tween = hidden_locations.create_tween()
	tween.tween_property(hidden_locations, 'modulate', color, 0.5)

func _on_visible_block_notifier_screen_exited() -> void:
	if $Player.position.y < -125:
		$LevelElements/Blocks/Section8/Block7.global_position = Vector2i(2078, 59)

func _on_section6_world_trigger_entered(_body: Node2D) -> void:
	$LevelElements/Platforms/Section6a/AnimationPlayer2.play('section_6')

func on_section6_block_entered_lava(body: Node2D) -> void:
	_block_set_position(body, Vector2i(1432, -193))

func _block_set_position(body: Block, position_value: Vector2) -> void:
	body.global_position = position_value

func _on_section_10_world_trigger_entered(body: Node2D) -> void:
	if 'light_source' in body:
		call_deferred("_set_area_light", body.light_source)
		call_deferred("_set_area_light", Cursor.light_source)

func _on_section_10_world_trigger_exited(body: Node2D) -> void:
	if 'light_source' in body:
		call_deferred("_set_area_light", body.light_source, false)
		call_deferred("_set_area_light", Cursor.light_source, false)

func _set_area_light(light_source: PointLight2D, enable: bool = true) -> void:
	light_source.enabled = true
	var new_energy: float = 2.0 if enable else 0.0
	var tween: Tween = light_source.create_tween()
	tween.tween_property(light_source, 'energy', new_energy, 0.5)

func _on_section_11_world_trigger_entered(_body: Node2D) -> void:
	$CutsceneManager.play_section_11_cutscene(BgmManager.song_time_left)
	wand_received = true

func _set_default_values() -> void:
	if wand_received:
		Globals.casting_disabled = true
		Globals.playing_cutscene = false

func _on_level_exit_area_entered(_body: Node2D) -> void:
	$LevelElements/InvisibleWalls/SectionExit/CollisionShape2D.call_deferred('set_disabled', false)

func _on_event_trigger_area_5_body_entered(_body: Node2D) -> void:
	$LevelElements/InvisibleWalls/SectionExit2/CollisionShape2D.call_deferred('set_disabled', false)
