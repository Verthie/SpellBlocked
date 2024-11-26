extends RigidBody2D

#const ICE_BLOCK_PHYSICS: Resource = preload('res://custom_scripts/ice_bock_physics.tres')

@onready var sprite_2d: Sprite2D = $Sprite2D

@export_enum("None", "Ice", "Anti-Gravity", "Enlarge") var block_type: String = "None"

var physics_resource: CustomResource
var rapier_ghost_collision_distance: float = ProjectSettings.get_setting('physics/rapier/logic/ghost_collision_distance_2d')

func _ready() -> void:
	apply_effect(block_type)

func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	for i in range(state.get_contact_count()):
		var reversed_body_velocity_normal: Vector2 = -state.linear_velocity.normalized()
		var collision_normal: Vector2 = state.get_contact_local_normal(i)
		var contact_position: Vector2 = state.get_contact_local_position(i)
		var contact_collider: Vector2 = state.get_contact_collider_position(i)
		var contact_to_collider_distance: float = (contact_position - contact_collider).length()
		print(reversed_body_velocity_normal.dot(collision_normal))
		if contact_to_collider_distance < rapier_ghost_collision_distance and reversed_body_velocity_normal.dot(collision_normal) > 0:
			$CollisionShape2D.disabled = true # disable contact i
			print("disabled contact: ", i)
		$CollisionShape2D.disabled = false # disable contact i
		#print(collision_normal)

func _physics_process(_delta: float) -> void:
	#PhysicsServer2D.
	#RapierDirectBodyState2D
	#RapierDirectSpaceState2Dg
	#print(get_contact_count())
	#print(get_colliding_bodies())
	pass


func destroy() -> void:
	queue_free()

func apply_effect(effect_type: String) -> void:
	match effect_type:
		"Ice":
			# Standard Mass, Low Friction, Rough False, Absorbent False
			#physics_resource = ICE_BLOCK_PHYSICS
			sprite_2d.self_modulate = Color("6eecff") # ice color
			#mass = physics_resource.mass
			#physics_material_override.friction = physics_resource.mat.friction
		"Anti-Gravity":
			# Standard Mass, Low Gravity, Low Friction, Rough False, Absorbent False
			# Block needs to accelarate to the ceiling and not allow player to jump from it, maybe using it could disable the jump
			sprite_2d.self_modulate = Color("9985ff") # anti-gravity color
		"Enlarge":
			pass # High Mass, High Friction, Rough True, Absorbent True
		_:
			sprite_2d.self_modulate = Color("ff836e") # standard color
