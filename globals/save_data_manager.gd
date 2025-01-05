extends Node

var settings_config: ConfigFile = ConfigFile.new()
var gamesave_config: ConfigFile = ConfigFile.new()

const SETTINGS_FILE_PATH: String = "user://settings.ini"
const GAMESAVE_FILE_PATH: String = "user://gamesave.ini"

func _ready() -> void:
	# Load data from a file.
	var err_settings: Error = settings_config.load(SETTINGS_FILE_PATH)
	var err_gamesave: Error = gamesave_config.load(GAMESAVE_FILE_PATH)

	# If the file didn't load, ignore it.
	if err_settings != OK:
		set_default_setting_values()

	if err_gamesave != OK:
		set_default_progress_values()

func set_default_setting_values() -> void:
	settings_config.set_value("video", "fullscreen", false)
	settings_config.set_value("video", "resolution", Vector2i(1280, 720))

	settings_config.set_value("audio", "master_volume", 0)
	settings_config.set_value("audio", "music_volume", -10)
	settings_config.set_value("audio", "sfx_volume", -10)

	settings_config.save(SETTINGS_FILE_PATH)

func set_default_progress_values() -> void:
	gamesave_config.set_value("progress", "level", 1)
	gamesave_config.save(GAMESAVE_FILE_PATH)

@warning_ignore('untyped_declaration')
func save_video_setting(key: String, value) -> void:
	settings_config.set_value("video", key, value)
	settings_config.save(SETTINGS_FILE_PATH)

func load_video_settings() -> Dictionary:
	var video_settings: Dictionary = {}
	for key: String in settings_config.get_section_keys("video"):
		video_settings[key] = settings_config.get_value("video", key)
	return video_settings

@warning_ignore('untyped_declaration')
func save_audio_setting(key: String, value) -> void:
	settings_config.set_value("audio", key, value)
	settings_config.save(SETTINGS_FILE_PATH)

func load_audio_settings() -> Dictionary:
	var audio_settings: Dictionary = {}
	for key: String in settings_config.get_section_keys("audio"):
		audio_settings[key] = settings_config.get_value("audio", key)
	return audio_settings

@warning_ignore('untyped_declaration')
func save_game_progress(key: String, value) -> void:
	gamesave_config.set_value("progress", key, value)
	gamesave_config.save(GAMESAVE_FILE_PATH)

func load_game_progress() -> Dictionary:
	var game_progress: Dictionary = {}
	for key: String in gamesave_config.get_section_keys("progress"):
		game_progress[key] = gamesave_config.get_value("progress", key)
	return game_progress

func clear_game_progress() -> void:
	gamesave_config.clear()
	set_default_progress_values()
