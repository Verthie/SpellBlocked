extends Node2D
class_name ParentLevel

func _ready():
	Globals.object_amounts = [0,0,0,0]

func _process(_delta):
	if Input.is_action_just_pressed('restart'):
		get_tree().reload_current_scene()

	if Input.is_action_just_pressed('quit'):
		get_tree().root.propagate_notification(NOTIFICATION_WM_CLOSE_REQUEST)
		get_tree().quit()
