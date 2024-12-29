extends Resource
class_name SoundEffectSettings

enum SoundEffectType{
	JUMP,
	LAND,
	CAST,
	CAST_APPLY_MOD,
	CAST_REMOVE_MOD,
	CAST_DESTROY,
	CAST_UNAVAILABLE,
	BLOCK_LAND,
	BLOCK_LAND_QUIET,
	BLOCK_JUMP_PAD,
	BUTTON_PRESS,
	HURT,
	MODIFIER_SWAP,
	UI_SELECT,
	UI_FOCUS,
	UI_BACK,
	PAUSE,
	UNPAUSE,
}

@export_range(0, 10) var limit: int = 5
@export var type: SoundEffectType
@export var sound_effect: AudioStream
@export_range(-40, 20) var volume: int = 0
@export_range(0.0, 4.0, .01) var pitch_scale: float = 1.0
@export_range(0.0, 1.0, .01) var pitch_randomness: float = 0.0
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
