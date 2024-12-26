extends Node2D

var sound_effect_dict: Dictionary = {}

@export var sound_effect_settings: Array[SoundEffectSettings]

func _ready() -> void:
	for sound_effect_setting: SoundEffectSettings in sound_effect_settings:
		sound_effect_dict[sound_effect_setting.type] = sound_effect_setting

func create_2d_audio_at_location(location: Vector2, type: SoundEffectSettings.SOUND_EFFECT_TYPE) -> void:
	if sound_effect_dict.has(type):
		var sound_effect_setting: SoundEffectSettings = sound_effect_dict[type]
		if sound_effect_setting.has_open_limit():
			sound_effect_setting.change_audio_count(1)
			var new_2d_audio: AudioStreamPlayer2D = AudioStreamPlayer2D.new()
			add_child(new_2d_audio)

			new_2d_audio.position = location
			new_2d_audio.bus = "SFX"
			new_2d_audio.stream = sound_effect_setting.sound_effect
			new_2d_audio.volume_db = sound_effect_setting.volume
			new_2d_audio.pitch_scale = sound_effect_setting.pitch_scale
			new_2d_audio.pitch_scale += randf_range(-sound_effect_setting.pitch_randomness, sound_effect_setting.pitch_randomness)
			new_2d_audio.attenuation = sound_effect_setting.attenuation
			new_2d_audio.max_distance = sound_effect_setting.max_distance
			new_2d_audio.finished.connect(sound_effect_setting.on_audio_finished)
			new_2d_audio.finished.connect(new_2d_audio.queue_free)

			new_2d_audio.play()
	else:
		push_error("Audio Manager failed to find setting for type ", type)

func create_audio(type: SoundEffectSettings.SOUND_EFFECT_TYPE) -> void:
	if sound_effect_dict.has(type):
		var sound_effect_setting: SoundEffectSettings = sound_effect_dict[type]
		if sound_effect_setting.has_open_limit():
			sound_effect_setting.change_audio_count(1)
			var new_audio: AudioStreamPlayer = AudioStreamPlayer.new()
			add_child(new_audio)

			new_audio.bus = "SFX"
			new_audio.stream = sound_effect_setting.sound_effect
			new_audio.volume_db = sound_effect_setting.volume
			new_audio.pitch_scale = sound_effect_setting.pitch_scale
			new_audio.pitch_scale += randf_range(-sound_effect_setting.pitch_randomness, sound_effect_setting.pitch_randomness)
			new_audio.finished.connect(sound_effect_setting.on_audio_finished)
			new_audio.finished.connect(new_audio.queue_free)

			new_audio.play()
	else:
		push_error("Audio Manager failed to find setting for type ", type)
