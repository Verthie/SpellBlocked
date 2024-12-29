extends Node

var current_scene: Node = null
var fallback_scenes: Array[Node] = []

func _ready() -> void:
	var root: Node = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

func goto_scene(scene_path: String, threaded: bool = false) -> void:
	_deferred_goto_scene.call_deferred(scene_path, threaded)

func _deferred_goto_scene(scene_path: String, threaded: bool) -> void:
	# Usuwanie obecnej sceny
	current_scene.free()

	# Ładowanie nowej sceny
	var scene: Resource = ResourceLoader.load_threaded_get(scene_path) if threaded else ResourceLoader.load(scene_path)
	current_scene = scene.instantiate()

	# Dodawanie aktywnej sceny do root'a
	get_tree().root.add_child(current_scene)

	get_tree().current_scene = current_scene
