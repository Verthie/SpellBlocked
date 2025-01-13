extends Node2D
class_name ParentLevel

signal restarted_or_exited(action: String)

const GAMEPLAY_MENU_PATH: String = 'res://scenes/ui/gameplay_menu.tscn'
const BLOCK: PackedScene = preload('res://scenes/objects/block.tscn')

@export_category("Level Settings")
@export var level_id: int = 0
@export var allow_casting: bool = true
@export var level_block_amount: int = 20
@export var level_music: BgmSettings.MusicType = BgmSettings.MusicType.LEVELTEST
@export var init_cursor_position: Vector2 = Vector2(640,360)
## If true resets the cursor's position to the init_cursor_position on game restart
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
var checkpoint_parameters: Dictionary = {}

var is_dark_background: bool = false

func _ready() -> void:
	SaveDataManager.save_game_progress("level", level_id)

	EventBus.casted.connect(_on_wand_cast)
	EventBus.changed_cursor_type.emit("Block")
	EventBus.entered_checkpoint.connect(_on_checkpoint_enter)
	EventBus.player_died.connect(_on_player_death)
	EventBus.game_restarted.connect(_restart.bind(TransitionManager.ShaderTransitionType.CURVED_DIAMONDS,  1, true))
	EventBus.game_paused.connect(_level_pause)
	EventBus.game_resumed.connect(_level_unpause)
	EventBus.gameplay_settings_entered.connect(_on_settings_enter)

	Cursor.show()
	InterfaceCursor.hide()

	if !allow_casting:
		Globals.casting_disabled = true
		$UI.hide()
		$Player.set_wand_sprite(false)
	else:
		$UI.show()

	Globals.block_amount = level_block_amount
	if SceneSwitcher.current_level == null:
		SceneSwitcher.current_level = self
	SceneSwitcher.fallback_scene_path = scene_file_path
	menu_scene = ResourceLoader.load('res://scenes/ui/gameplay_menu.tscn')
	settings_scene = ResourceLoader.load('res://scenes/ui/settings_menu.tscn')
	ResourceLoader.load_threaded_request(SceneSwitcher.current_level.scene_file_path)
	if reset_cursor_position_on_restart:
		Input.warp_mouse(init_cursor_position)
	else:
		if !Globals.started_level:
			Input.warp_mouse(init_cursor_position)
	Globals.started_level = true
	BgmManager.create_audio(level_music)

	if !Globals.level_checkpoint.is_empty() and Globals.level_checkpoint.keys()[0] == level_id:
		checkpoint_parameters = Globals.level_checkpoint[level_id]
		#print(checkpoint_parameters)
		for parameter: String in checkpoint_parameters:
			if parameter == "player_position":
				$Player.position = checkpoint_parameters[parameter]
				#print(checkpoint_parameters[parameter])
				#print($Player.position)
				var camera_times_position_x: int = $Player.position.x / 180
				#print(camera_times_position_x)
				$ScreenCamera.position.x = camera_times_position_x * 305
				#print($ScreenCamera.position.x)
			elif parameter == "music_clip_index":
				BgmManager.set_interactive_audioclip(checkpoint_parameters[parameter])

	if Globals.switching:
		await get_tree().create_timer(restart_input_block_time).timeout
		Globals.input_enabled = true
		Globals.switching = false
	if Globals.game_paused:
		_level_unpause()
		Globals.game_paused = false

func _input(event: InputEvent) -> void:
	if !Globals.switching and !TransitionManager.transitioning:
		if event.is_action_pressed('restart'):
			restarted_or_exited.emit('restart')
			call_deferred("_restart", TransitionManager.ShaderTransitionType.CURVED_DIAMONDS, 1)
		elif event.is_action_pressed('quit'):
			if !Globals.game_paused:
				_level_pause()
			else:
				_level_unpause()
			#restarted_or_exited.emit('quit')

func _on_wand_cast() -> void:
	var block_instance: Block = BLOCK.instantiate()
	block_instance.position = get_local_mouse_position()
	$Blocks.add_child(block_instance)

func _on_checkpoint_enter(checkpoint_id: int, save_parameters: int) -> void:
	print("saving")
	print("current clip index: ", BgmManager.current_clip_index)
	Globals.set_level_checkpoint(checkpoint_id, save_parameters, level_id, $Player.position, BgmManager.current_clip_index)

func _on_player_death() -> void:
	if !full_level_restart_on_death:
		$Player.position = initial_player_position
	elif !Globals.switching:
		$ScreenCamera.add_trauma(0.3)
		Globals.switching = true
		Globals.input_enabled = false
		await get_tree().create_timer(1).timeout
		Globals.switching = false
		await restarted_or_exited

func _restart(transition_type: TransitionManager.ShaderTransitionType = TransitionManager.ShaderTransitionType.NONE, transition_speed: float = 1.0, text_button_restart: bool = false) -> void:
	AudioManager.create_audio(SoundEffectSettings.SoundEffectType.UI_BACK)
	Globals.switching = true
	Globals.input_enabled = false

	TransitionManager.layer = 3
	if transition_type == TransitionManager.ShaderTransitionType.NONE:
		SceneSwitcher.goto_scene(SceneSwitcher.current_level.scene_file_path)
	else:
		TransitionManager.play_shader_transition(transition_type, true, transition_speed)
		await TransitionManager.finished
		if text_button_restart:
			Globals.game_paused = false
			get_tree().paused = false

		SceneSwitcher.goto_scene(SceneSwitcher.current_level.scene_file_path, true)
		TransitionManager.play_shader_transition(transition_type, false, transition_speed, true)


func _level_pause() -> void:
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

func _level_unpause() -> void:
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
