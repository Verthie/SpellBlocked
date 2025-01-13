extends TileMapLayer

const SPLASH_EFFECT: PackedScene = preload('res://scenes/world/splash_effect.tscn')

var init_liquid_level: int = 0

func _ready() -> void:
	EventBus.object_splashed.connect(_on_object_splash)
	var y: int = -50
	while(init_liquid_level == 0):
		for x: int in range(0, 500, 5):
			var cell_id: int = get_cell_source_id(Vector2i(x, y))
			if cell_id == 4:
				init_liquid_level = int(map_to_local(Vector2i(x, y)).y - 4)
				Globals.liquid_height_level = init_liquid_level
				return
		y += 1

func _on_object_splash(body: Node2D, splash_position: Vector2i) -> void:
	body.z_index = z_index - 1
	var splash_node: AnimatedSprite2D = SPLASH_EFFECT.instantiate()
	splash_node.position = Vector2(splash_position.x, Globals.liquid_height_level)
	splash_node.z_index = z_index
	add_child(splash_node)
	await splash_node.animation_finished
	splash_node.queue_free()
