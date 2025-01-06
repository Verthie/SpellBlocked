extends Node

signal changed_block_amount(value: int)

const DEFAULT_BLOCK_PROPERTIES: CustomResource = preload('res://scenes/objects/block_properties/default_block_properties.tres')
const ICE_BLOCK_PROPERTIES: CustomResource = preload('res://scenes/objects/block_properties/ice_block_properties.tres')
const STONE_BLOCK_PROPERTIES: CustomResource = preload('res://scenes/objects/block_properties/stone_block_properties.tres')
const ANTI_GRAVITY_BLOCK_PROPERTIES: CustomResource = preload('res://scenes/objects/block_properties/anti-gravity_block_properties.tres')

const block_properties: Dictionary = {"None": DEFAULT_BLOCK_PROPERTIES, "Ice": ICE_BLOCK_PROPERTIES, "Stone": STONE_BLOCK_PROPERTIES, "Anti-Gravity": ANTI_GRAVITY_BLOCK_PROPERTIES}

var volumes: Array[int] = [0, -10, -10]

var in_modify_state: bool = false

var current_block_type: String = "None"
	#set(value):
		#current_block_type = value

var current_level_id: int = 0
var switching: bool = false
var game_paused: bool = false
var input_enabled: bool = true

var liquid_height_level: int = 0

var block_amount: int:
	set(value):
		block_amount = value
		changed_block_amount.emit(block_amount)

var started_level: bool = false

func _process(_delta: float) -> void:
	if current_block_type == "None":
		in_modify_state = false
	else:
		in_modify_state = true

func load_resources(path: String, extension: String = "") -> Dictionary:
	var resources: Dictionary = {}
	var dir: DirAccess = DirAccess.open(path)
	if dir:
		var file_names: PackedStringArray = dir.get_files()
		if file_names:
			for file_name: String in file_names:
				var loaded_resource: Resource = ResourceLoader.load(path + file_name)

				if "type" in loaded_resource:
					resources[loaded_resource.type] = loaded_resource
				elif extension != "":
					if file_name.get_slice(".", 1) == "gdshader":
						resources[file_name.get_slice(".", 0)] = loaded_resource
				else:
					resources[file_name] = loaded_resource
	return resources

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
