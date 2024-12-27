extends Node

var current_scene: Node = null

func _ready() -> void:
	var root: Node = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

func goto_scene(scene: PackedScene) -> void:
	_deferred_goto_scene.call_deferred(scene.resource_path)

func _deferred_goto_scene(path: String) -> void:
	# Usuwanie obecnej sceny
	current_scene.free()

	# Ładowanie nowej sceny
	var s: Resource = ResourceLoader.load(path)
	current_scene = s.instantiate()

	# Dodawanie aktywnej sceny do root'a
	get_tree().root.add_child(current_scene)

	get_tree().current_scene = current_scene
