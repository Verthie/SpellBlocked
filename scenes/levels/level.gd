extends Node2D
class_name ParentLevel

const BLOCK: PackedScene = preload('res://scenes/objects/block.tscn')

@export var level_block_amount: int = 99

func _ready() -> void:
	EventBus.casted.connect(_on_wand_cast)
	Globals.block_amount = level_block_amount

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed('restart'):
		get_tree().reload_current_scene()

	if Input.is_action_just_pressed('quit'):
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
		get_tree().quit()

func _on_wand_cast() -> void:
	var block_instance: Block = BLOCK.instantiate()
	block_instance.position = get_local_mouse_position()
	$Blocks.add_child(block_instance)
