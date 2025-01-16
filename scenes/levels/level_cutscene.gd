class_name LevelCutscene
extends Node

func _ready() -> void:
	EventBus.level_finished.connect(_on_level_finish)

func play_level_enter_cutscene() -> void:
	pass

func play_level_exit_cutscene() -> void:
	pass

func _on_level_finish() -> void:
	play_level_exit_cutscene()
