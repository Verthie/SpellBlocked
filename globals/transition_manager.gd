extends CanvasLayer

signal finished

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var overlay: ColorRect = $Overlay

@export var init_transition_color: Color = Color("000000")

var shader_dict: Dictionary = {}

var transitioning: bool = false

enum TransitionType {
	NONE,
	DISSOLVE,
}

enum ShaderTransitionType {
	NONE,
	RECTANGLES,
	CURVED_DIAMONDS,
	DARK_BLUR
}

func _ready() -> void:
	shader_dict = Globals.load_resources("res://resources/shaders/transitions/", "gdshader")

func play_transition(type: TransitionType, speed: float = 1.0, backwards: bool = false, transition_color: Color = init_transition_color) -> void:
	var transition_name: String = str(TransitionType.keys()[type]).to_lower()

	overlay.color = transition_color

	if transition_name in animation_player.get_animation_list():
		if !backwards:
			animation_player.play(transition_name, -1, speed)
		else:
			animation_player.play(transition_name, -1, -speed, true)
		await animation_player.animation_finished
		finished.emit()
	else:
		push_error("Transition Manager failed to find this type ", type)

func play_shader_transition(type: ShaderTransitionType, fill: bool = true, speed: float = 1.0, backwards: bool = false, delay: float = 0.0, progress_start_over: float = 0.0, progress_end_over: float = 1.0, transition_color: Color = init_transition_color) -> void:
	var transition_name: String = str(ShaderTransitionType.keys()[type]).to_lower()

	show()
	overlay.color = transition_color

	if shader_dict.has(transition_name):
		var duration: float = 1.0 / speed
		var progress_start: float
		var progress_end: float

		if (fill and !backwards) or (!fill and backwards):
			progress_start = 0.0
			progress_end = 1.0
		elif (fill and backwards) or (!fill and !backwards):
			progress_start = 1.0
			progress_end = 0.0

		progress_start = progress_start_over if progress_start_over != 0.0 else progress_start
		progress_end = progress_end_over if progress_end_over != 1.0 else progress_end

		overlay.material.set("shader_parameter/progress", progress_start)
		overlay.modulate = ("ffffff") #if fill else ("ffffff00")
		overlay.material.shader = shader_dict[transition_name]
		overlay.material.set("shader_parameter/fill", fill)

		if !transitioning:
			transitioning = true
			var tween: Tween = create_tween()
			await tween.tween_method(_set_shader_progress, progress_start, progress_end, duration).set_delay(delay).finished
			transitioning = false
			finished.emit()
		if (fill and backwards) or (!fill and !backwards):
			hide()
	else:
		push_error("Transition Manager failed to find this type ", type)

func _set_shader_progress(progress: float) -> void:
	overlay.material.set("shader_parameter/progress", progress)
