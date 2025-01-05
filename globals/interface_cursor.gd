extends CanvasLayer

@export_range(1, 16, 1) var init_cursor_size: int = 6

func _ready() -> void:
	$Cursor.scale = Vector2(init_cursor_size, init_cursor_size)

func set_cursor_size(value: int) -> void:
	$Cursor.scale = Vector2(value, value)
