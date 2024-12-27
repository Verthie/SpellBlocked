extends Resource
class_name BgmSettings

enum MUSIC_TYPE{
	LEVELTEST,
	LEVEL1
}

@export_range(0, 10) var limit: int = 1
@export var type: MUSIC_TYPE
@export var music: AudioStream
@export var music_loop_version: AudioStream
@export var loop: bool = true
@export_range(-40, 20) var volume: int = 0
@export_range(0.0, 4.0, .01) var pitch_scale: float = 1.0
#@export_range(0.0, 1.0, .01) var pitch_randomness: float = 0.0
## The volume is attenuated over distance with this as an exponent.
@export var attenuation: float = 1.0
## Maximum distance from which audio is still hearable.
@export var max_distance: float = 2000.0

var audio_count: int = 0

func change_audio_count(amount: int) -> void:
	audio_count = max(0, audio_count + amount)

func has_open_limit() -> bool:
	return audio_count < limit

func on_audio_finished() -> void:
	change_audio_count(-1)
