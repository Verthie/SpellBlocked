extends Node2D
class_name ParentLevel

const BLOCK: PackedScene = preload('res://scenes/objects/block.tscn')

@export_category("Level Settings")
@export var level_block_amount: int = 99
@export var level_music: BgmSettings.MusicType = BgmSettings.MusicType.LEVELTEST
@export var cursor_position: Vector2 = Vector2(640,360)
@export var reset_cursor_position_on_restart: bool = false
@export var full_level_restart_on_death: bool = true

@onready var initial_player_position: Vector2 = $Player.position

var warped: bool = false
var restarting: bool = true

func _ready() -> void:
	EventBus.casted.connect(_on_wand_cast)
	EventBus.changed_cursor_type.emit("Block")
	EventBus.player_died.connect(_on_player_death)
	Globals.block_amount = level_block_amount
	BgmManager.create_audio(level_music)
	if reset_cursor_position_on_restart:
		Input.warp_mouse(cursor_position)
	else:
		if !Globals.started_level:
			Input.warp_mouse(cursor_position)
	Globals.started_level = true
	restarting = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed('restart') and !restarting:
		AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_BACK)
		call_deferred("_restart", TransitionManager.TransitionType.DISSOLVE, 2.5)

	if Input.is_action_just_pressed('quit'):
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
		get_tree().quit()

func _on_wand_cast() -> void:
	var block_instance: Block = BLOCK.instantiate()
	block_instance.position = get_local_mouse_position()
	$Blocks.add_child(block_instance)

func _on_player_death() -> void:
	if !full_level_restart_on_death:
		$Player.position = initial_player_position
	elif !restarting:
		call_deferred("_restart", TransitionManager.TransitionType.DISSOLVE, 1.5, true)

func _restart(transition_type: TransitionManager.TransitionType, transition_speed: float = 0, player_death: bool = false) -> void:
	restarting = true
	if player_death:
		$ScreenCamera.add_trauma(0.3)
		await get_tree().create_timer(0.3).timeout
	await TransitionManager.play_transition(transition_type, false, transition_speed)
	get_tree().reload_current_scene()
	TransitionManager.play_transition(transition_type, true, transition_speed)
