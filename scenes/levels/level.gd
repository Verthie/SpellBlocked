extends Node2D
class_name ParentLevel

var block_cursor = preload('res://assets/sprites/cursor/block_cursor.png')

func _ready():
	Globals.object_amounts = [0,0,0,0]
	block_cursor.resize(32,32,Image.INTERPOLATE_NEAREST)
	Input.set_custom_mouse_cursor(block_cursor)

func _process(_delta):
	if Input.is_action_just_pressed('restart'):
		get_tree().reload_current_scene()

	if Input.is_action_just_pressed('quit'):
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
		get_tree().quit()
