class_name LiquidTile
extends TileMapLayer

const SPLASH_EFFECT: PackedScene = preload('res://scenes/world/splash_effect.tscn')

## If this value is lower or equal to [code]0[/code] the script will automatically find the [b]liquid level[/b] using the parameters below.[br][br]Make sure [param search_start_point] is [b]not below[/b] the liquid tilemap and [param search_area_width] covers at least a part of the liquid tilemap
@export var init_liquid_level: int = 0
## This refers to the point (global position) at which the search will start, search goes from left to right
@export var search_start_point: Vector2i = Vector2i(0,-50)
## The width in which the search will occur, the lower the value the smaller the area it will search through
@export var search_area_width: int = 500
## Here you can set the width of the largest pool in order to allow automatic level finder find the water level faster.[br][br]WARNING: [param largest_liquid_pool_width] can't be higher than intersecting tilemap
@export_range(1, 10000, 1) var largest_liquid_pool_width: int = 5

func _ready() -> void:
	EventBus.object_splashed.connect(_on_object_splash)
	var y: int = search_start_point.y
	if largest_liquid_pool_width > search_area_width:
		largest_liquid_pool_width = search_area_width - 1
	if init_liquid_level <= 0:
		while(init_liquid_level <= 0):
			for x: int in range(search_start_point.x, search_area_width + search_start_point.x, largest_liquid_pool_width):
				var cell_id: int = get_cell_source_id(Vector2i(x, y))
				if cell_id == 4:
					init_liquid_level = int(map_to_local(Vector2i(x, y)).y - 4)
					return
			y += 1
	else:
		init_liquid_level -= 4
	print(self, " ", init_liquid_level)

func _on_object_splash(body: Node2D, splash_position: Vector2i, collider: Node2D) -> void:
	if collider == self:
		body.z_index = z_index - 1
		var splash_node: AnimatedSprite2D = SPLASH_EFFECT.instantiate()
		splash_node.position = Vector2(splash_position.x, init_liquid_level)
		splash_node.z_index = z_index
		#print("body z_index: ", body.z_index, "| tilemap z_index: ", z_index, "| splash z_index: ", splash_node.z_index)
		add_child(splash_node)
		await splash_node.animation_finished
		splash_node.queue_free()
