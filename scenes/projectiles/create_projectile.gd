extends ParentProjectile

# Pocisk ma tworzyć obiekty o wybranym typie z ui (pod warunkiem że jest ilość) na pozycji zderzenia pocisku z czymkolwiek
const OBJECT_1 = preload('res://scenes/objects/object_1.tscn')

signal create(pos: Vector2, type: PackedScene)

func _on_body_entered(_body):
	var projectile_position: Vector2 = $'.'.global_position
	#print(projectile_position)
	create.emit(projectile_position, OBJECT_1)
	queue_free()
