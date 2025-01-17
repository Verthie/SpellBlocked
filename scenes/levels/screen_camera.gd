extends Camera2D

@onready var noise: FastNoiseLite = FastNoiseLite.new()
var noise_y: int = 0

@export_category("Static camera allignment")
## The target that camera follows
@export var target: Player
## The amount of time it takes camera to align when transitioning between scenes
@export var align_time: float = 1
## The size/boundry of a scene
@export var screen_size: Vector2 = Vector2(320, 190)

@export_category("Shaking effect")
## Determines how quickly the shaking stops
@export_range(0, 1, 0.1) var decay: float = 0.8
## Maximum hor/ver shake in pixels
@export var max_offset: Vector2 = Vector2(100, 75)
### Maximum rotation in radians
#@export var max_roll: float = 0
## Trauma exponent
@export_range(1, 3, 1) var trauma_power: int = 2

var desired_position: Vector2 = Vector2(0,0)

## Current shake strength
var trauma: float = 0.0

var transitioning: bool = false

#func _input(event: InputEvent) -> void:
	#if event is InputEventKey and event.pressed and event.keycode == KEY_0:
		#add_trauma(0.2)

func _ready() -> void:
	noise.seed = randi()
	noise.frequency = 0.2

func _process(delta: float) -> void:
	if trauma:
		trauma = max(trauma - decay * delta, 0)
		_shake()

func _physics_process(_delta: float) -> void:

	# Animated camera alignment on scene switch
	var tween: Tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUINT)
	await tween.tween_property(self, "global_position", _desired_position(), align_time).finished

func add_trauma(amount: float) -> void:
	trauma = min(trauma + amount, 1.0)

func _shake() -> void:
	var amount: float = pow(trauma, trauma_power)
	#rotation = max_roll * amount * randf_range(-1, 1)
	#offset.x = max_offset.x * amount * randf_range(-1, 1)
	#offset.y = max_offset.y * amount * randf_range(-1, 1)

	noise_y += 1
	#rotation = max_roll * amount * noise.get_noise_2d(noise.seed, noise_y)
	offset.x = max_offset.x * amount * noise.get_noise_2d(1, noise_y)
	offset.y = max_offset.y * amount * noise.get_noise_2d(100, noise_y)

func _desired_position() -> Vector2:
	#print("Player global position: ", Target.global_position, " Camera position: ", (Target.global_position / screen_size).floor() * screen_size + screen_size/2)
	return (target.global_position / screen_size).floor() * screen_size + screen_size/2
