extends Node2D
class_name ParentLevel

const BLOCK: PackedScene = preload('res://scenes/objects/block.tscn')

func _ready() -> void:
	EventBus.casted.connect(_on_wand_cast)
	# EventBus.modified_property.connect(_on_wand_modify)
	#Globals.object_amounts = [0,0,0,0]

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed('restart'):
		get_tree().reload_current_scene()

	if Input.is_action_just_pressed('quit'):
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
		get_tree().quit()

func _on_wand_cast() -> void:
	var block_instance: RigidBody2D = BLOCK.instantiate()
	block_instance.position = get_local_mouse_position()
	$Blocks.add_child(block_instance)

# func _on_wand_modify(block: Node2D, block_property: String) -> void:
# 	match block_property:
# 		"anti-gravity":
# 			pass
# 			# block.add_child(anti-gravity_component) #TODO
# 		"ice":
# 			pass
# 			# block.add_child(ice_component) #TODO
# 		"size":
# 			pass
# 			# block.add_child(size_component) # component ten będzie musiał zawierać informacje o tym czy blok jest enlarged czy nie #TODO
