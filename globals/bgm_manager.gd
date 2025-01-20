extends Node2D

signal triggered_clip_switch(clip_index: int)

var music_dict: Dictionary = {}
@warning_ignore('untyped_declaration')
var current_audio
var current_music_setting: BgmSettings

var audio_stream_interactive: AudioStreamInteractive
var current_clip_index: int = -1

var checkpoint_clip_index: int = 0
var global_clip_length: float = 0
var global_clip_length_holder: float = 0
var filler_global_clip_length: float = 0
var tracking_position: bool = false
var timer_loop_count: int = 0
var timer: Timer
var last_clip_position: float = 0
var true_position: float = 0
var song_time_left: float = 0
var position_offset: float = 0
var position_offset_holder: float = 0
var offset_applicable: bool = false
var can_set_parameter: bool = false
var is_filler_clip: bool = false

func _ready() -> void:
	music_dict = Globals.load_resources("res://resources/properties/bgm/")
	EventBus.quick_restarted.connect(_on_quick_restart)
	EventBus.game_restarted.connect(_on_game_restart)
	EventBus.level_finished.connect(_on_level_finished)
	EventBus.level_exited.connect(_on_level_exited)
	triggered_clip_switch.connect(_on_clip_switch_trigger)

func _process(_delta: float) -> void:
	if tracking_position:
		var current_position: float = global_clip_length - timer.time_left
		last_clip_position += current_position - last_clip_position
		#print("OFFSET: ", position_offset)
		true_position = last_clip_position + position_offset
		# adds the offset from the position of when the last clip played giving the true current position of the clip and not from the beginning
		if true_position >= global_clip_length:
			true_position -= global_clip_length
			#print(true_position)
		song_time_left = global_clip_length - true_position
		#print("song true position: ", true_position, " || timer time left: ", timer.time_left)
		#print("song position with offset: ", true_position, " || song timer position: ", last_clip_position)
		#print("song position: ", true_position, " || song time left: ", song_time_left)
		#print("song time left: ", song_time_left)

		if song_time_left <= 0.02:
			if is_filler_clip:
				_initiate_filler_playback_position_tracking(filler_global_clip_length)
			print("CLIP FINISHED")

func create_2d_audio_at_location(location: Vector2, type: BgmSettings.MusicType) -> void:
	if music_dict.has(type):
		current_music_setting = music_dict[type]
		if current_music_setting.has_open_limit():
			current_music_setting.change_audio_count(1)
			current_audio = AudioStreamPlayer2D.new()
			add_child(current_audio)

			current_audio.position = location
			current_audio.bus = "Music"
			current_audio.stream = current_music_setting.music if !current_music_setting.loop else current_music_setting.music_loop_version
			current_audio.volume_db = current_music_setting.volume
			current_audio.pitch_scale = current_music_setting.pitch_scale
			current_audio.attenuation = current_music_setting.attenuation
			current_audio.max_distance = current_music_setting.max_distance

			current_audio = current_audio

			if !current_music_setting.loop:
				if current_audio.stream is not AudioStreamRandomizer:
					current_audio.finished.connect(current_music_setting.on_audio_finished)
					current_audio.finished.connect(current_audio.queue_free)
				elif current_audio.stream is AudioStreamRandomizer:
					current_audio.finished.connect(_next_track)

			if current_audio.stream is AudioStreamInteractive:
				audio_stream_interactive = current_audio.stream
				if checkpoint_clip_index:
					set_interactive_audioclip(checkpoint_clip_index)
				else:
					set_interactive_audioclip(audio_stream_interactive.initial_clip, true)
				play_audio()
			else:
				play_audio()
	else:
		push_error("Audio Manager failed to find setting for type ", type)

func create_audio(type: BgmSettings.MusicType) -> void:
	if music_dict.has(type):
		current_music_setting = music_dict[type]
		if current_music_setting.has_open_limit():
			current_music_setting.change_audio_count(1)
			current_audio = AudioStreamPlayer.new()
			add_child(current_audio)

			current_audio.bus = "Music"
			current_audio.stream = current_music_setting.music if !current_music_setting.loop else current_music_setting.music_loop_version
			current_audio.volume_db = current_music_setting.volume
			current_audio.pitch_scale = current_music_setting.pitch_scale

			if !current_music_setting.loop:
				if current_audio.stream is not AudioStreamRandomizer:
					current_audio.finished.connect(current_music_setting.on_audio_finished)
					current_audio.finished.connect(current_audio.queue_free)
				elif current_audio.stream is AudioStreamRandomizer:
					current_audio.finished.connect(_next_track)

			if current_audio.stream is AudioStreamInteractive:
				audio_stream_interactive = current_audio.stream
				if checkpoint_clip_index:
					set_interactive_audioclip(checkpoint_clip_index)
				else:
					set_interactive_audioclip(audio_stream_interactive.initial_clip, true)
				play_audio()
			else:
				play_audio()

	else:
		push_error("Audio Manager failed to find setting for type ", type)

func remove_audio(fade_in_out: bool = true, fade_duration: float = 0.5) -> void:
	if fade_in_out:
		current_music_setting.on_audio_finished()
		await _fade_volume(fade_in_out, fade_duration)
		current_audio.queue_free()
		_fade_volume(fade_duration, false)
	else:
		current_audio.queue_free()

func stop_audio(fade_out: bool = false, fade_duration: float = 0.5) -> void:
	if fade_out:
		await _fade_volume(fade_out, fade_duration)
	if get_child(0):
		var audio: AudioStreamPlayer = get_child(0)
		audio.stop()

func play_audio() -> void:
	await _fade_volume(false)
	current_audio.play()

func set_checkpoint_clip_index(clip_index: int = 0) -> void:
	checkpoint_clip_index = clip_index

func set_interactive_audioclip(clip_index: int = 0, track_position: bool = true, auto_override: bool = false) -> void:
	if audio_stream_interactive != null and clip_index != current_clip_index and clip_index < audio_stream_interactive.clip_count:
		if audio_stream_interactive.get_clip_name(clip_index) != null:

			if audio_stream_interactive.initial_clip == clip_index:
				await get_tree().create_timer(0.75).timeout

			var clip_name: String = audio_stream_interactive.get_clip_name(clip_index)
			var clip_stream: AudioStream = audio_stream_interactive.get_clip_stream(clip_index)
			var current_clip_length: float = clip_stream.get_length()
			print("clip name: ", clip_name, " || clip length: ", current_clip_length)
			if !global_clip_length:
				global_clip_length = current_clip_length
				#print("global_clip_length: ", global_clip_length)

			if current_clip_length != global_clip_length:
				#print("THEY ARE DIFFERENT")
				#print("AS SOON AS THE CLIP FINISHES TRIGGER FILLER PLAYBACK TRACKING")
				is_filler_clip = true
				global_clip_length_holder = global_clip_length
				#global_clip_length = current_clip_length
				filler_global_clip_length = current_clip_length
				track_position = false
			elif tracking_position:
				_end_playback_position_tracking()

			#print(audio_stream_interactive.get_transition_from_time(current_clip_index, clip_index)) # Throws errors don't know why
			#print(audio_stream_interactive.get_transition_to_time(current_clip_index, clip_index))

			current_clip_index = clip_index

			var has_auto_mode: bool

			if !auto_override:
				has_auto_mode = audio_stream_interactive.get_clip_auto_advance(clip_index)
			else:
				has_auto_mode = auto_override

			if !has_auto_mode or can_set_parameter:
				current_audio.set("parameters/switch_to_clip", clip_name)
				can_set_parameter = false

			if auto_override:
				has_auto_mode = false

			if track_position:
				_initiate_playback_position_tracking(global_clip_length, has_auto_mode)

func restart_interactive_audio_clip(track_position: bool = true, full_restart: bool = false) -> void:
	var clip_index: int = audio_stream_interactive.initial_clip
	if checkpoint_clip_index: # checkpoint overrites the restart clip index
		clip_index = checkpoint_clip_index

	#print("clip index: ", clip_index, " || clip index before restart: ", current_clip_index)
	#print("setting clip to number: ", clip_index)
	if audio_stream_interactive != null and clip_index != current_clip_index and audio_stream_interactive.get_clip_name(clip_index) != null:

		if full_restart:
			await get_tree().create_timer(1.75).timeout

		var clip_name: String = audio_stream_interactive.get_clip_name(clip_index)
		var clip_stream: AudioStream = audio_stream_interactive.get_clip_stream(clip_index)
		var current_clip_length: float = clip_stream.get_length()
		print("clip name: ", clip_name, " || clip length: ", current_clip_length)

		global_clip_length = current_clip_length

		current_clip_index = clip_index

		var has_auto_mode: bool = audio_stream_interactive.get_clip_auto_advance(clip_index)

		if !has_auto_mode:
			current_audio.set("parameters/switch_to_clip", clip_name)

		if full_restart and track_position:
			_initiate_playback_position_tracking(global_clip_length, has_auto_mode)

func _fade_volume(fade_out: bool = true, fade_duration: float = 0.5) -> void:
	var tween: Tween = create_tween()
	if fade_out:
		await tween.tween_method(_set_bus_volume, Globals.volumes[1], -40.0, fade_duration).finished
	if !fade_out:
		await tween.tween_method(_set_bus_volume, AudioServer.get_bus_volume_db(1), Globals.volumes[1], fade_duration).finished

func _next_track() -> void:
	if current_audio.stream is AudioStreamRandomizer:
		await get_tree().create_timer(0.5).timeout
		current_audio.play()

func _set_bus_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(1, value)

func _on_quick_restart() -> void:
	if audio_stream_interactive != null:
		restart_interactive_audio_clip()

func _on_game_restart() -> void:
	await stop_audio()
	AudioServer.set_bus_mute(1, true)
	if audio_stream_interactive != null:
		_set_previous_clip_globals()
		checkpoint_clip_index = 0
		current_clip_index = -1
		restart_interactive_audio_clip(true, true)
	play_audio()
	AudioServer.set_bus_mute(1, false)

func _on_level_finished() -> void:
	_set_previous_clip_globals()
	if audio_stream_interactive != null:
		checkpoint_clip_index = 0
		global_clip_length = 0
		current_clip_index = -1
		_end_playback_position_tracking()
	await remove_audio()

func _on_level_exited() -> void:
	await stop_audio()
	AudioServer.set_bus_mute(1, true)
	if audio_stream_interactive != null:
		checkpoint_clip_index = 0
		_end_playback_position_tracking()
	await remove_audio()
	AudioServer.set_bus_mute(1, false)

func _initiate_playback_position_tracking(current_clip_length: float = 0, has_auto_mode: bool = false) -> void:
	last_clip_position += position_offset
	timer = Timer.new()
	timer.timeout.connect(_add_to_timer_loop_counter)
	if has_auto_mode:
		timer.timeout.connect(_end_playback_position_tracking)
		timer.timeout.connect(set_interactive_audioclip.bind(current_clip_index + 1, true, true))
		timer.timeout.connect(set_checkpoint_clip_index.bind(current_clip_index + 1))
	add_child(timer)
	timer.start(current_clip_length)
	tracking_position = true

func _end_playback_position_tracking() -> void:
	position_offset = 0
	if offset_applicable:
		position_offset = true_position
	print("clip position offset: ", position_offset)
	timer_loop_count = 0
	#global_clip_length = 0
	tracking_position = false
	if timer != null:
		timer.queue_free()
	offset_applicable = false


func _add_to_timer_loop_counter() -> void:
	timer_loop_count += 1
	#print("current amount of timer loops: ", timer_loop_count)

func _initiate_filler_playback_position_tracking(current_clip_length: float = 0) -> void:
	#print("INITIATED FILLER PLAYBACK TRACKING")
	is_filler_clip = false
	global_clip_length = current_clip_length
	position_offset_holder = position_offset
	position_offset = 0
	if timer != null:
		timer.queue_free()
	last_clip_position = 0
	true_position = 0
	timer = Timer.new()
	timer.timeout.connect(_set_previous_clip_globals)
	timer.timeout.connect(set_interactive_audioclip.bind(current_clip_index + 1, true, true))
	add_child(timer)
	timer.start(global_clip_length)
	tracking_position = true

func _set_previous_clip_globals() -> void:
	global_clip_length = global_clip_length_holder
	position_offset = 0
	tracking_position = false
	last_clip_position = 0
	true_position = 0
	if timer != null:
		timer.queue_free()

func _on_clip_switch_trigger(clip_index: int, override_global_clip_length: float = 0) -> void:
	offset_applicable = true
	can_set_parameter = true
	if override_global_clip_length:
		global_clip_length = override_global_clip_length
	#print("triggered clip_index: ", clip_index)
	#print("current clip index: ", current_clip_index)
	set_interactive_audioclip(clip_index, true)
