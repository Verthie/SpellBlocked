extends Resource
class_name CustomResource

@export_category("Properties")
@export_enum("None", "Ice", "Large") var type_name: String = "None"
@export_range(0.0, 1.0, 0.025) var friction: float = 0.175
@export var gravity: float = 400
@export var colour: Color = Color("ff836e")
@export_range(0.0, 1.0, 0.1) var modifier_overlay_opacity: float = 0.5
