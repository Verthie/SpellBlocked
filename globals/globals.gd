extends Node

signal changed_block_amount(value: int)

const DEFAULT_BLOCK_PROPERTIES: CustomResource = preload('res://resources/properties/block_types/default_block_properties.tres')
const ICE_BLOCK_PROPERTIES: CustomResource = preload('res://resources/properties/block_types/ice_block_properties.tres')
const STONE_BLOCK_PROPERTIES: CustomResource = preload('res://resources/properties/block_types/stone_block_properties.tres')
const ANTI_GRAVITY_BLOCK_PROPERTIES: CustomResource = preload('res://resources/properties/block_types/anti-gravity_block_properties.tres')

const block_properties: Dictionary = {"None": DEFAULT_BLOCK_PROPERTIES, "Ice": ICE_BLOCK_PROPERTIES, "Stone": STONE_BLOCK_PROPERTIES, "Gravity": ANTI_GRAVITY_BLOCK_PROPERTIES}

var volumes: Array[int] = [0, -10, -10]

var allowed_modifiers: Array[String] = ["Ice", "Stone", "Gravity"]
var in_modify_state: bool = false

var current_block_type: String = "None":
	set(value):
		current_block_type = value
		Cursor.change_cursor_color(block_properties[current_block_type].cursor_colour)

var current_level_id: int = 0
var switching: bool = false
var game_paused: bool = false
var input_enabled: bool = true
var playing_cutscene: bool = false
var quick_restarted: bool = false

var casting_disabled: bool = false
var throwing_disabled: bool = false
var modifying_disabled: bool = false

var level_checkpoint: Dictionary = {}
var previous_checkpoint_id: int = 0

var liquid_height_level: int = 0

var block_amount: int:
	set(value):
		block_amount = value
		changed_block_amount.emit(block_amount)

var started_level: bool = false

var initial_block_positions: Array[Vector2i] = []

func _ready() -> void:
	EventBus.changed_block_type.connect(_check_modify_state)
	EventBus.quick_restarted.connect(_on_quick_restart)

func load_resources(path: String, extension: String = "") -> Dictionary:
	var resources: Dictionary = {}
	var dir: DirAccess = DirAccess.open(path)
	if dir:
		var file_names: PackedStringArray = dir.get_files()
		if file_names:
			for file_name: String in file_names:
				var loaded_resource: Resource = load_asset(path + file_name)

				if "type" in loaded_resource:
					resources[loaded_resource.type] = loaded_resource
				elif extension != "":
					if file_name.get_slice(".", 1) == "gdshader":
						resources[file_name.get_slice(".", 0)] = loaded_resource
				else:
					resources[file_name] = loaded_resource
	return resources

static func load_asset(path : String) -> Resource:
	if OS.has_feature("export"):
		# Check if file is .remap
		if not path.ends_with(".remap"):
			return load(path)

		# Open the file
		var __config_file: ConfigFile = ConfigFile.new()
		__config_file.load(path)

		# Load the remapped file
		var __remapped_file_path: String = __config_file.get_value("remap", "path")
		__config_file = null
		return load(__remapped_file_path)
	else:
		return load(path)

func update_volume(bus_index: int, value: int) -> void:
	volumes[bus_index] += value
	AudioServer.set_bus_volume_db(bus_index, volumes[bus_index])

func set_pause_subtree(root: Node, pause: bool) -> void:
	var process_setters: Array[String] = ["set_process",
	"set_physics_process",
	"set_process_input",
	"set_process_unhandled_input",
	"set_process_unhandled_key_input",
	"set_process_shortcut_input",]

	for setter: String in process_setters:
		root.propagate_call(setter, [!pause])

func set_level_checkpoint(checkpoint_id: int, saved_parameters: int, level_id: int = 1, player_pos: Vector2 = Vector2(0,0), music_clip_index: int = 0) -> void:
	reset_level_checkpoint()
	var checkpoint_parameters: Dictionary = {}
	match saved_parameters:
		1:
			checkpoint_parameters = {"player_position": player_pos}
		3:
			checkpoint_parameters = {"player_position": player_pos, "music_clip_index": music_clip_index}
		_:
			pass
	if !checkpoint_parameters.is_empty():
		previous_checkpoint_id = checkpoint_id
		level_checkpoint[level_id] = checkpoint_parameters

func reset_level_checkpoint() -> void:
	level_checkpoint.clear()
	previous_checkpoint_id = 0

func _check_modify_state() -> void:
	if current_block_type == "None":
		in_modify_state = false
	else:
		in_modify_state = true

func _on_quick_restart() -> void:
	quick_restarted = true
