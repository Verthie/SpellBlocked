extends Node2D

const BLOCK: PackedScene = preload('res://scenes/objects/block.tscn')

@onready var ray_cast_2d: RayCast2D = $RayCast2D

@export_enum("none", "anti-gravity", "ice", "size") var block_property: String = "none"

var object_amount: int = 0
var raycast_obstruction: bool = false # Zależne od kolizji raycasta
var can_cast: bool = false # Zależne od kolizji obszaru kursora <vvv
var can_modify: bool = false
var received_body: Node2D = null
var body_type: String = ""

func _ready() -> void:
	# object_amount = Globals.object_amount #TODO
	Cursor.cursor_changed_state.connect(_on_cursor_state_change)

func _process(_delta: float) -> void:
	ray_cast_2d.look_at(get_global_mouse_position())
	ray_cast_2d.target_position.x = get_local_mouse_position().length()

	#if ray_cast_2d.is_colliding(): #TODO
		#print("colliding with: ", ray_cast_2d.get_collider())
		#raycast_obstruction = true

	if Input.is_action_just_pressed('cast') and !raycast_obstruction and can_cast: # and object_amount > 0 #TODO
		EventBus.casted.emit()
		can_cast = false
	# elif object_amount == 0: #TODO
	# 	print("no blocks")

	#TODO Dodać warunki dla nadawania właściwości blokom (pamiętaj że ustaliłeś właściwości jako komponenty bloka)
	if Input.is_action_just_pressed('cast') and !raycast_obstruction and can_modify: # and body_type == "rigidbody":
		# EventBus.modified_property.emit(received_body, block_property)

		match block_property:
			"anti-gravity": #TODO
				pass
				# received_body.add_child(anti-gravity_component)
			"ice": #TODO
				pass
				# received_body.add_child(ice_component)
			"size": #TODO
				pass
				# if !received_body.enlarged:
					# received_body.add_child(size_component) # component ten będzie musiał zawierać informacje o tym czy blok jest enlarged czy nie
					# received_body.enlarged = true
				# else received_body.enlarged:
					# received_body.remove_child(size_component)
					# received_body.enlarged = false

		can_modify = false

	if Input.is_action_just_pressed('cast_destroy') and !raycast_obstruction and can_modify:
		if "destroy" in received_body:
			received_body.destroy()
		can_modify = false

func _on_cursor_state_change(colliding_body: Node2D, current_body_type: String, cast_allowed: bool, modification_allowed: bool) -> void:
	received_body = colliding_body
	body_type = current_body_type
	can_cast = cast_allowed
	can_modify = modification_allowed
