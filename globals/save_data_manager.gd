extends Node

var score_data: Dictionary = {}
var config: ConfigFile = ConfigFile.new()

const SETTINGS_FILE_PATH: String = "user://settings.ini"

func _ready() -> void:
	# Load data from a file.
	var err: Error = config.load(SETTINGS_FILE_PATH)

	# If the file didn't load, ignore it.
	if err != OK:
		config.set_value("video", "fullscreen", false)
		config.set_value("video", "resolution", Vector2i(1280, 720))

		config.set_value("audio", "master_volume", 0)
		config.set_value("audio", "music_volume", -10)
		config.set_value("audio", "sfx_volume", -10)

		config.save(SETTINGS_FILE_PATH)

@warning_ignore('untyped_declaration')
func save_video_setting(key: String, value) -> void:
	config.set_value("video", key, value)
	config.save(SETTINGS_FILE_PATH)

func load_video_settings() -> Dictionary:
	var video_settings: Dictionary = {}
	for key: String in config.get_section_keys("video"):
		video_settings[key] = config.get_value("video", key)
	return video_settings

@warning_ignore('untyped_declaration')
func save_audio_setting(key: String, value) -> void:
	config.set_value("audio", key, value)
	config.save(SETTINGS_FILE_PATH)

func load_audio_settings() -> Dictionary:
	var audio_settings: Dictionary = {}
	for key: String in config.get_section_keys("audio"):
		audio_settings[key] = config.get_value("audio", key)
	return audio_settings
