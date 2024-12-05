extends CanvasLayer

var block_type_choosen: String

# Kolory
var colour: Color = Color("ffffff")

@onready var choice_bar: Array[Node] = $ChoiceBar.get_children(true)

# Funkcja inicjalizująca standardowe wartości
func _ready() -> void:
	Globals.current_block_type = "None"
	set_current_type(Globals.current_block_type)
	#Globals.connect("ui_update", update_counters)
	#Globals.connect("ui_current", set_current_type)
	#update_counters(0,0)

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event.keycode == KEY_1 or event.keycode == KEY_2):
		match event.keycode:
			KEY_1:
				Globals.current_block_type = "Ice" if Globals.current_block_type != "Ice" else "None"
			KEY_2:
				Globals.current_block_type = "Enlarge" if Globals.current_block_type != "Enlarge" else "None"

		set_current_type(Globals.current_block_type)

#func update_counters(type: int, amount: int) -> void:
	#choice_bar[type].get_child(1).text = str(amount)

func set_current_type(block_type: String) -> void:

	colour = Color("ffffff")

	for node: Node in choice_bar:
		var counter: Array[Node] = node.get_children()
		for element: Label in counter:
			element.modulate = colour

	if block_type != "None":
		var current_counter: int

		match block_type:
			"Ice":
				current_counter = 0
				colour = Color('93f0ff')
			"Enlarge":
				current_counter = 1
				colour = Color('93969c')

		choice_bar[current_counter].get_child(0).modulate = colour
		choice_bar[current_counter].get_child(1).modulate = colour
