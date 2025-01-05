extends Node

signal changed_scene

var current_scene: Node = null
var current_gameplay_scene: Node = null
var current_level: ParentLevel = null
var fallback_scene_path: String = ""

func _ready() -> void:
	var root: Node = get_tree().root
	current_scene = root.get_child(root.get_child_count() - 1)

func goto_scene(scene_path: String, threaded: bool = false) -> void:
	_deferred_goto_scene.call_deferred(scene_path, threaded)

func goto_previous_scene(threaded: bool = false) -> void:
	if fallback_scene_path != "":
		_deferred_goto_scene.call_deferred(fallback_scene_path, threaded)
	else:
		push_error("There are no fallback scenes in array")

#func goto_gameplay_scene(scene_path: String, threaded: bool = false) -> void:
	##current_level.hide()
	#_deferred_goto_gameplay_scene.call_deferred(scene_path, threaded)
#
#func return_from_gameplay_scene() -> void:
	#_deferred_return_from_gameplay_scene.call_deferred()
#
#func _deferred_return_from_gameplay_scene() -> void:
	#current_gameplay_scene.queue_free()
	#if current_level != null:
		#get_tree().current_scene = current_level
	#else:
		#push_error("No level was previously loaded")

func _deferred_goto_scene(scene_path: String, threaded: bool) -> void:
	# Usuwanie obecnej sceny
	current_scene.queue_free()

	# Ładowanie nowej sceny
	var scene: Resource = ResourceLoader.load_threaded_get(scene_path) if threaded else ResourceLoader.load(scene_path)
	current_scene = scene.instantiate()

	if current_scene is ParentLevel:
		current_level = current_scene

	# Dodawanie aktywnej sceny do root'a
	get_tree().root.add_child(current_scene)

	get_tree().current_scene = current_scene

#func _deferred_goto_gameplay_scene(scene_path: String, threaded: bool = false) -> void:
#
	## Ładowanie nowej sceny
	#var gameplay_scene: Resource = ResourceLoader.load_threaded_get(scene_path) if threaded else ResourceLoader.load(scene_path)
	#current_gameplay_scene = gameplay_scene.instantiate()
#
	## Dodawanie aktywnej sceny do root'a
	#get_tree().root.add_child(current_gameplay_scene)
#
	#get_tree().current_scene = current_gameplay_scene
