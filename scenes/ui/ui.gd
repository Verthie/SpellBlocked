extends CanvasLayer

@onready var choice_bar: Array[Node] = $ChoiceBar.get_children(true)
@onready var amount: Label = $BoxCounter/Text/Amount

func _ready() -> void:
	Globals.changed_block_amount.connect(update_counter)
	Globals.current_block_type = "None"
	set_current_ui_type()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and (event.keycode == KEY_1 or event.keycode == KEY_2 or event.keycode == KEY_3):
		match event.keycode:
			KEY_1:
				Globals.current_block_type = "Ice" if Globals.current_block_type != "Ice" else "None"
			KEY_2:
				Globals.current_block_type = "Stone" if Globals.current_block_type != "Stone" else "None"
			KEY_3:
				Globals.current_block_type = "Anti-Gravity" if Globals.current_block_type != "Anti-Gravity" else "None"

		set_current_ui_type()

func set_current_ui_type() -> void:

	for control: Control in choice_bar:
		var modifier_sprites: Array[Node] = control.get_children()
		modifier_sprites[1].visible = false

	if Globals.current_block_type != "None":
		var current_counter: int

		match Globals.current_block_type:
			"Ice":
				current_counter = 0
			"Stone":
				current_counter = 1
			"Anti-Gravity":
				current_counter = 2

		choice_bar[current_counter].get_child(1).visible = true

func update_counter(value: int) -> void:
	amount.text = str(value)
	if value == 0 and amount.self_modulate == Color("ffffff"):
		amount.self_modulate = Color("ffa8a8")
	elif value > 0 and amount.self_modulate == Color("ffa8a8"):
		amount.self_modulate = Color("ffffff")
