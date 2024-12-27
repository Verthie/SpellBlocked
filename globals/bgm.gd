extends Node2D

@export var music_settings: Array[BgmSettings]

var music_dict: Dictionary = {}
@warning_ignore('untyped_declaration')
var current_audio

func _ready() -> void:
	for music_setting: BgmSettings in music_settings:
		music_dict[music_setting.type] = music_setting

func create_2d_audio_at_location(location: Vector2, type: BgmSettings.MUSIC_TYPE) -> void:
	if music_dict.has(type):
		var music_setting: BgmSettings = music_dict[type]
		if music_setting.has_open_limit():
			music_setting.change_audio_count(1)
			var new_2d_audio: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
			add_child(new_2d_audio)

			new_2d_audio.position = location
			new_2d_audio.bus = "Music"
			new_2d_audio.stream = music_setting.music if !music_setting.loop else music_setting.music_loop_version
			new_2d_audio.volume_db = music_setting.volume
			new_2d_audio.pitch_scale = music_setting.pitch_scale
			new_2d_audio.attenuation = music_setting.attenuation
			new_2d_audio.max_distance = music_setting.max_distance

			if !music_setting.loop and new_2d_audio.stream is not AudioStreamRandomizer:
				new_2d_audio.finished.connect(music_setting.on_audio_finished)
				new_2d_audio.finished.connect(new_2d_audio.queue_free)
			elif !music_setting.loop and new_2d_audio.stream is AudioStreamRandomizer:
				current_audio = new_2d_audio
				new_2d_audio.finished.connect(_next_track)

			new_2d_audio.play()
	else:
		push_error("Audio Manager failed to find setting for type ", type)

func create_audio(type: BgmSettings.MUSIC_TYPE) -> void:
	if music_dict.has(type):
		var music_setting: BgmSettings = music_dict[type]
		if music_setting.has_open_limit():
			music_setting.change_audio_count(1)
			var new_audio: AudioStreamPlayer = AudioStreamPlayer.new()
			add_child(new_audio)

			new_audio.bus = "Music"
			new_audio.stream = music_setting.music if !music_setting.loop else music_setting.music_loop_version
			new_audio.volume_db = music_setting.volume
			new_audio.pitch_scale = music_setting.pitch_scale

			if !music_setting.loop and new_audio.stream is not AudioStreamRandomizer:
				new_audio.finished.connect(music_setting.on_audio_finished)
				new_audio.finished.connect(new_audio.queue_free)
			elif !music_setting.loop and new_audio.stream is AudioStreamRandomizer:
				current_audio = new_audio
				new_audio.finished.connect(_next_track)

			new_audio.play()
	else:
		push_error("Audio Manager failed to find setting for type ", type)

func _next_track() -> void:
	if current_audio.stream is AudioStreamRandomizer:
		current_audio.play()
