extends CanvasLayer

@onready var choice_bar: Array[Node] = $ChoiceBar.get_children(true)
@onready var amount: Label = $BoxCounter/Text/Amount

func _ready() -> void:
	Globals.changed_block_amount.connect(update_counter)
	EventBus.changed_block_type.connect(set_current_ui_type)
	EventBus.block_removed.connect(_block_removal.unbind(1))
	Globals.current_block_type = "None"

func set_current_ui_type() -> void:

	for control: Control in choice_bar:
		var modifier_sprites: Array[Node] = control.get_children()
		var activated_modifier: Sprite2D = modifier_sprites[1]
		activated_modifier.hide()

	if Globals.current_block_type != "None":
		#var current_counter: int

		match Globals.current_block_type:
			"Ice":
				$ChoiceBar/Ice/IceModEnabled.show()
			"Stone":
				$ChoiceBar/Stone/StoneModEnabled.show()
			"Gravity":
				$ChoiceBar/Gravity/GravityModEnabled.show()

		#choice_bar[current_counter].get_child(1).visible = true

func update_counter(value: int) -> void:
	amount.text = str(value)
	if value == 0 and amount.self_modulate == Color("ffffff"):
		amount.self_modulate = Color("ffa8a8")
	elif value > 0 and amount.self_modulate == Color("ffa8a8"):
		amount.self_modulate = Color("ffffff")

func _block_removal() -> void:
	if !visible: show()
	#TODO some ui animations when getting a block
