extends Node

@export var attribute_decorator_scene: PackedScene = preload('res://scenes/objects/block_modifier/attribute_decorator.tscn')
@export var modifier: CustomResource

func apply(target: Node) -> void:
	#print("---APPLYING MODIFIER---")
	_modifier(target, "friction")
	_modifier(target, "gravity")

func _modifier(target: Node, attribute: String) -> void:
	var attribute_decorator: Node = attribute_decorator_scene.instantiate()
	attribute_decorator.decoratee = target.get(attribute)
	attribute_decorator.amount = modifier.friction if attribute == "friction" else modifier.gravity
	attribute_decorator.attribute_type = attribute
	attribute_decorator.modifier_applied = true if owner.current_modifiers.size() > 0 else false
	attribute_decorator.current_modifiers = owner.current_modifiers
	add_child(attribute_decorator)

	target.set(attribute, attribute_decorator)

func remove(target: Node) -> void:
	if "decoratee" in target.friction:
		target.friction = target.friction.decoratee
		target.gravity = target.gravity.decoratee

		if [target.friction.amount, target.gravity.amount] == target.original_values:
			var modifiers: Array[Node] = get_parent().get_children()
			for modifier_node: Node in modifiers:
				for decorator: Node in modifier_node.get_children():
					decorator.queue_free()
