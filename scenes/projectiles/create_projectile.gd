extends ParentProjectile

# Pocisk ma tworzyć obiekty o wybranym typie z ui (pod warunkiem że jest ilość) na pozycji zderzenia pocisku z podłożem bądź innymi obiektami

const OBJECT_1: PackedScene = preload('res://scenes/objects/object_1.tscn')
const OBJECT_2: PackedScene = preload('res://scenes/objects/object_2.tscn')

var objects: Dictionary = {0: OBJECT_1, 1: OBJECT_2}

signal create(pos: Vector2, type: PackedScene)

var stored_type: int

func _ready():
	$SelfDestructTimer.start()
	Globals.current_object_amount_create -= 1
	stored_type = Globals.current_object_type

#TODO Pocisk musi sprawdzać czy koliduje z wieloma obiektami, nawet gdy kolizja będzie z wieloma obiektami dalej musi tworzyć tylko jeden obiekt, a nie duplikować je

func _on_body_entered(_body) -> void:
	var projectile_position: Vector2 = $'.'.global_position
	#print(projectile_position)
	create.emit(projectile_position, objects[stored_type])
	queue_free()

func _on_self_destruct_timer_timeout() -> void:
	Globals.object_type_destroy = stored_type
	queue_free()
