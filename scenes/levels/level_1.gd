extends ParentLevel

func _on_area_2d_body_entered(_body):
	call_deferred("change_scene", "res://scenes/levels/level_2.tscn")
	
func change_scene(scene_path: String):
	get_tree().change_scene_to_file(scene_path)
