extends CanvasLayer

var block_type_choosen: String

# Kolory
var colour: Color = Color("ffffff")

@onready var choice_bar: Array[Node] = $ChoiceBar.get_children(true)

func _ready() -> void:
	Globals.current_block_type = "None"
	set_current_ui_type()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event.keycode == KEY_1 or event.keycode == KEY_2):
		match event.keycode:
			KEY_1:
				Globals.current_block_type = "Ice" if Globals.current_block_type != "Ice" else "None"
			KEY_2:
				Globals.current_block_type = "Stone" if Globals.current_block_type != "Stone" else "None"

		set_current_ui_type()

#func update_counters(type: int, amount: int) -> void:
	#choice_bar[type].get_child(1).text = str(amount)

func set_current_ui_type() -> void:

	colour = Color("ffffff")

	for node: Node in choice_bar:
		var counter: Array[Node] = node.get_children()
		for element: Label in counter:
			element.modulate = colour

	if Globals.current_block_type != "None":
		var current_counter: int

		match Globals.current_block_type:
			"Ice":
				current_counter = 0
			"Stone":
				current_counter = 1

		colour = Globals.block_properties[Globals.current_block_type].colour

		choice_bar[current_counter].get_child(0).modulate = colour
		choice_bar[current_counter].get_child(1).modulate = colour
