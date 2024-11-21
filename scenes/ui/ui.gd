extends CanvasLayer

# Kolory
var default: Color = Color("ffffff")
var purple: Color = Color("b287ff")

#@onready var choice_bar: HBoxContainer = $ChoiceBar.get_children(true)

# Funkcja inicjalizująca standardowe wartości
#func _ready() -> void:
	#Globals.connect("ui_update", update_counters)
	#Globals.connect("ui_current", set_current_type)
	#update_counters(0,0)
	#set_current_type(0,0)

#func update_counters(type: int, amount: int) -> void:
	#choice_bar[type].get_child(1).text = str(amount)

#func set_current_type(previous_type: int, current_type: int) -> void:
	#choice_bar[previous_type].get_child(0).modulate = default
	#choice_bar[previous_type].get_child(1).modulate = default
	#choice_bar[current_type].get_child(0).modulate = purple
	#choice_bar[current_type].get_child(1).modulate = purple
