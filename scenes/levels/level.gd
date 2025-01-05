extends Node2D
class_name ParentLevel

signal game_restarted

const GAMEPLAY_MENU_PATH: String = 'res://scenes/ui/gameplay_menu.tscn'
const BLOCK: PackedScene = preload('res://scenes/objects/block.tscn')

@export_category("Level Settings")
@export var level_block_amount: int = 99
@export var level_music: BgmSettings.MusicType = BgmSettings.MusicType.LEVELTEST
@export var init_cursor_position: Vector2 = Vector2(640,360)
## If true resets the cursor's position to the center of the viewport
@export var reset_cursor_position_on_restart: bool = false
## If true reloads the whole scene on death, if false only restarts player's position
@export var full_level_restart_on_death: bool = true
## The time it takes for input to be allowed after level restart
@export_range(0.0, 3.0, 0.1) var restart_input_block_time: float = 0.5

@onready var initial_player_position: Vector2 = $Player.position

var warped: bool = false

var menu_scene: PackedScene = null
var menu_node: Control = null
var settings_scene: PackedScene = null
var settings_node: Control = null

var is_dark_background: bool = false

func _ready() -> void:
	EventBus.casted.connect(_on_wand_cast)
	EventBus.changed_cursor_type.emit("Block")
	EventBus.player_died.connect(_on_player_death)
	EventBus.game_restarted.connect(_restart.bind(TransitionManager.ShaderTransitionType.CURVED_DIAMONDS,  1, false, true))
	EventBus.game_paused.connect(level_pause)
	EventBus.game_resumed.connect(level_unpause)
	EventBus.gameplay_settings_entered.connect(_on_settings_enter)
	Cursor.show()
	InterfaceCursor.hide()
	Globals.block_amount = level_block_amount
	SceneSwitcher.fallback_scene_path = scene_file_path
	menu_scene = ResourceLoader.load('res://scenes/ui/gameplay_menu.tscn')
	settings_scene = ResourceLoader.load('res://scenes/ui/settings_menu.tscn')
	if reset_cursor_position_on_restart:
		Input.warp_mouse(init_cursor_position)
	else:
		if !Globals.started_level:
			Input.warp_mouse(init_cursor_position)
	Globals.started_level = true
	BgmManager.create_audio(level_music)
	if Globals.restarting:
		await get_tree().create_timer(restart_input_block_time).timeout
		Globals.input_enabled = true
		Globals.restarting = false
	else:
		BgmManager.play_audio()
	if Globals.game_paused:
		level_unpause()
		Globals.game_paused = false

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed('restart') and Globals.input_enabled and !TransitionManager.transitioning:
		AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_BACK)
		call_deferred("_restart", TransitionManager.ShaderTransitionType.CURVED_DIAMONDS, 1)

	if Input.is_action_just_pressed('quit') and !Globals.restarting and !TransitionManager.transitioning:
		if !Globals.game_paused:
			#AudioServer.set_bus_mute(1, true)
			SceneSwitcher.fallback_scene_path = self.scene_file_path
			level_pause()
		else:
			#AudioServer.set_bus_mute(1, false)
			level_unpause()

func _on_wand_cast() -> void:
	var block_instance: Block = BLOCK.instantiate()
	block_instance.position = get_local_mouse_position()
	$Blocks.add_child(block_instance)

func _on_player_death() -> void:
	if !full_level_restart_on_death:
		$Player.position = initial_player_position
	elif !Globals.restarting:
		call_deferred("_restart", TransitionManager.ShaderTransitionType.CURVED_DIAMONDS,  1, true)

func _restart(transition_type: TransitionManager.ShaderTransitionType = TransitionManager.ShaderTransitionType.NONE, transition_speed: float = 1.0, player_death: bool = false, text_button_restart: bool = false) -> void:
	Globals.restarting = true
	Globals.input_enabled = false

	if player_death:
		$ScreenCamera.add_trauma(0.3)
		await get_tree().create_timer(0.3).timeout

	TransitionManager.layer = 3
	if transition_type == TransitionManager.ShaderTransitionType.NONE:
		SceneSwitcher.goto_scene(SceneSwitcher.current_level.scene_file_path)
	else:
		TransitionManager.play_shader_transition(transition_type, true, transition_speed)
		await TransitionManager.finished
		if text_button_restart:
			BgmManager._next_track()
			Globals.game_paused = false
			get_tree().paused = false
		SceneSwitcher.goto_scene(SceneSwitcher.current_level.scene_file_path)
		TransitionManager.play_shader_transition(transition_type, false, transition_speed, true)


func level_pause() -> void:
	Globals.game_paused = true
	get_tree().paused = true

	if !is_dark_background:
		TransitionManager.layer = 1
		TransitionManager.blur_game(0.6, 5.0)
		await TransitionManager.finished
	is_dark_background = true

	if settings_node != null:
		settings_node.hide()
	if !menu_node:
		menu_node = menu_scene.instantiate()
		$Menu.add_child(menu_node)

	EventBus.changed_cursor_type.emit("Select")

	$Menu.visible = true

func level_unpause() -> void:
	Globals.game_paused = false
	get_tree().paused = false

	EventBus.changed_cursor_type.emit("Block")

	TransitionManager.layer = 3
	TransitionManager.blur_game(0.6, 5.0, true)
	await TransitionManager.finished
	is_dark_background = false

	$Menu.visible = false

func _on_settings_enter() -> void:
	if menu_node != null:
		menu_node.hide()
	if !settings_node:
		settings_node = settings_scene.instantiate()
		$Menu.add_child(settings_node)
