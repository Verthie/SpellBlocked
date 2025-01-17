extends ParentLevel

@onready var hidden_locations: Node2D = $TileMaps/NoCollisionPlanes/ForegroundPlanes/HiddenLocations

func _on_hidden_area_access_body_entered(body: Node2D) -> void:
	if body is Block:
		call_deferred("_enable_hidden_area_access")

func _enable_hidden_area_access() -> void:
	$LevelElements/InvisibleWalls/HiddenAreaAccessEnable/CollisionShape2D.disabled = false
	$LevelElements/InvisibleWalls/HiddenAreaAccessPrevent/CollisionShape2D.disabled = true

func _on_hidden_area_body_entered(_body: Node2D) -> void:
	call_deferred("_set_area_transparency", false)

func _on_hidden_area_body_exited(_body: Node2D) -> void:
	call_deferred("_set_area_transparency")

func _set_area_transparency(transparency_state: bool = true) -> void:
	if hidden_locations == null:
		return
	var color: Color = Color('ffffff00') if transparency_state else Color('ffffffe6')
	var tween: Tween = get_tree().create_tween()
	tween.tween_property($TileMaps/NoCollisionPlanes/ForegroundPlanes/HiddenLocations, 'modulate', color, 0.5)
