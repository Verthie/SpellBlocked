extends CutsceneManager

@onready var cutscene_player: AnimationPlayer = $CutscenePlayer
@onready var cursor_sprite: Sprite2D = $Sprites/Cursor

func play_section_11_cutscene(area_song_time_left: float) -> void:
	Globals.playing_cutscene = true
	#INFO Filler Hallway
	player.animation_player.play("run")
	player.direction = 1.0
	var player_y_position: float = player.global_position.y
	var cutscene_duration: float = 0
	if area_song_time_left < 10.25:
		#TODO add quick filler cutscene instead of timer
		var filler_time: float = BgmManager.global_clip_length + area_song_time_left - 10.25 # 10 is the second in the song time left from which the filler will end
		var filler_marker_x_position: float = $MovePlayerLocation2.global_position.x
		var player_filler_walk: Tween = player.create_tween()
		await player_filler_walk.tween_property(player, 'global_position', Vector2(filler_marker_x_position, player_y_position), filler_time).finished
		#await get_tree().create_timer(filler_time).timeout
		cutscene_duration = BgmManager.song_time_left - 4.5
	else:
		cutscene_duration = area_song_time_left - 4.5

	var marker_x_position: float = $MovePlayerLocation.global_position.x
	var player_point_arrival: Tween = player.create_tween()
	await player_point_arrival.tween_property(player, 'global_position', Vector2(marker_x_position, player_y_position), cutscene_duration).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT).finished

	player.velocity.x = 0
	player.animation_player.play("idle")
	var cursor_transparent_tween: Tween = Cursor.create_tween()
	#cursor_transparent_tween.tween_property(Cursor, 'modulate', Color(Cursor.modulate, 0), 0.25)
	cursor_transparent_tween.set_parallel()
	cursor_transparent_tween.tween_property(Cursor.light_source, 'energy', 0, 0.25)
	await get_tree().create_timer(BgmManager.song_time_left - 3).timeout
	$'../LevelElements/Labels/Cutscene Playing'.show()
	$'../LevelElements/Mechanisms/Section11/GateRune'.gate_on()
	$'../LevelElements/Mechanisms/Section11/GateRune2'.gate_on()
	await BgmManager.clip_started
	#INFO The Main Cutscene
	Globals.mouse_enabled = false
	cursor_sprite.global_position = Cursor.global_position
	cursor_sprite.show()
	Cursor.hide()
	var light_source_node_copy: PointLight2D = Cursor.light_source.duplicate()
	Cursor.light_source.enabled = false
	cursor_sprite.add_child(light_source_node_copy)
	cutscene_player.play('wand_encounter')
	set_process_unhandled_input(false)
	await get_tree().create_timer(BgmManager.song_time_left).timeout
	#INFO After Cutscene
	$'../LevelElements/Labels/Cutscene Playing'.hide()
	var light_tween: Tween = create_tween()
	#light_tween.tween_property(Cursor, 'modulate', Color(Cursor.modulate, 1), 0.25)
	light_tween.set_parallel()
	light_tween.tween_property(player.light_source, 'energy', 0, 0.75)
	light_tween.tween_property(cursor_sprite.get_node('LightSource'), 'energy', 1.5, 0.25)
	await light_tween.tween_property(cursor_sprite.get_node('LightSource'), 'texture_scale', 35, 2).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).finished
	light_tween.stop()
	cursor_sprite.get_node('LightSource').reparent($'../ScreenCamera')
	#var light_tween: Tween = create_tween()
	#light_tween.set_parallel()
	#light_tween.tween_property(Cursor.light_source, 'energy', 0, 0.7)
	#light_tween.tween_property($'../Lighting/TextureRect', 'modulate', Color($'../Lighting/TextureRect'.modulate, 0), 1)
	#await light_tween.tween_property($'../Lighting/TextureRect2', 'modulate', Color($'../Lighting/TextureRect2'.modulate, 0), 1).finished
	#$'../Lighting/TextureRect'.queue_free()
	#$'../Lighting/TextureRect2'.queue_free()
	var mouse_tween: Tween = cursor_sprite.create_tween()
	await mouse_tween.tween_property(cursor_sprite, 'global_position', $'../ScreenCamera'.global_position, 1).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT).finished
	player.set_wand_sprite(true)
	player.can_jump = false
	player.current_state = "cast_remove"
	player.animation_player.play("cast_remove")
	await player.animation_player.animation_finished
	Globals.mouse_enabled = true
	Input.warp_mouse(Vector2(640,360))
	Globals.playing_cutscene = false
	await get_tree().create_timer(0.1).timeout
	Globals.casting_disabled = false
	cursor_sprite.hide()
	Cursor.show()
