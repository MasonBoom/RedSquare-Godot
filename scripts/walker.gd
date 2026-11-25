extends CharacterBody3D

@export_range(1.0, 12.0) var walk_speed := 4.6
@export_range(2.0, 18.0) var run_speed := 8.2
@export var acceleration := 24.0
@export var gravity := 15.0
@export var jump_speed := 5.0
@export_range(0.0005, 0.006, 0.0001) var mouse_sensitivity := 0.0022
@export_range(-25.0, 25.0) var starting_pitch := 5.0

@onready var eyes: Camera3D = $Eyes
@onready var footsteps: AudioStreamPlayer = $Footsteps

const STEPS = [
	preload("res://audio/step_1.wav"),
	preload("res://audio/step_2.wav"),
	preload("res://audio/step_3.wav")
]
var spawn_transform := Transform3D.IDENTITY
var step_distance := 0.0
var step_index := 0


func set_spawn(marker: Marker3D) -> void:
	spawn_transform = marker.global_transform
	respawn()


func respawn() -> void:
	global_transform = spawn_transform
	eyes.rotation.x = deg_to_rad(starting_pitch)
	velocity = Vector3.ZERO
	step_distance = 0.0
	reset_physics_interpolation()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		var dragging: bool = (event.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not dragging:
			return
		rotate_y(-event.screen_relative.x * mouse_sensitivity)
		eyes.rotation.x = clampf(eyes.rotation.x - event.screen_relative.y * mouse_sensitivity,
				deg_to_rad(-82.0), deg_to_rad(82.0))
	elif event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED


func _physics_process(delta: float) -> void:
	var turn := Input.get_axis("look_right", "look_left")
	rotate_y(turn * 1.8 * delta)
	var input := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := global_transform.basis * Vector3(input.x, 0.0, input.y)
	var speed := run_speed if Input.is_action_pressed("sprint") else walk_speed
	var planar := Vector2(velocity.x, velocity.z).move_toward(
			Vector2(direction.x, direction.z) * speed, acceleration * delta)
	velocity.x = planar.x
	velocity.z = planar.y
	if is_on_floor():
		velocity.y = jump_speed if Input.is_action_just_pressed("jump") else 0.0
	else:
		velocity.y -= gravity * delta
	var previous := global_position
	move_and_slide()
	if global_position.y < -10.0:
		respawn()
		return
	if is_on_floor() and input.length_squared() > 0.0:
		var distance := Vector2(global_position.x - previous.x, global_position.z - previous.z).length()
		step_distance += distance
		var stride := 2.08 if speed == run_speed else 1.80
		if step_distance >= stride:
			step_distance = fmod(step_distance, stride)
			footsteps.stream = STEPS[step_index]
			footsteps.pitch_scale = [0.96, 1.04, 1.0][step_index] * (1.06 if speed == run_speed else 1.0)
			footsteps.play()
			step_index = (step_index + 1) % STEPS.size()
	else:
		step_distance = 0.0
