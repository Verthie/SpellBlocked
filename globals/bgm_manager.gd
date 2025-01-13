extends Node2D

var music_dict: Dictionary = {}
@warning_ignore('untyped_declaration')
var current_audio
var current_music_setting: BgmSettings
var current_clip_index: int = 0

func _ready() -> void:
	music_dict = Globals.load_resources("res://resources/properties/bgm/")
	EventBus.game_restarted.connect(_on_game_restart)
	EventBus.level_finished.connect(_on_level_finished)
	EventBus.level_exited.connect(_on_level_exited)

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

func set_interactive_audioclip(clip_index: int = 0) -> void:
	if current_audio.stream is AudioStreamInteractive and clip_index != current_clip_index:
		if current_audio.stream.get_clip_name(clip_index) != null:
			current_clip_index = clip_index
			var clip_name: String = current_audio.stream.get_clip_name(clip_index)
			print(clip_name)
			current_audio.set("parameters/switch_to_clip", clip_name)

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

func _on_game_restart() -> void:
	await stop_audio()
	AudioServer.set_bus_mute(1, true)
	set_interactive_audioclip()
	await play_audio()
	AudioServer.set_bus_mute(1, false)

func _on_level_finished() -> void:
	await remove_audio()

func _on_level_exited() -> void:
	await stop_audio()
	AudioServer.set_bus_mute(1, true)
	await remove_audio()
	AudioServer.set_bus_mute(1, false)
