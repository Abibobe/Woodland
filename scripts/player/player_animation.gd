class_name PlayerAnimation
extends AnimatedSprite2D


enum Facing {
	DOWN,
	UP,
	SIDE
}

var last_footstep_time_ms: int = -1000

@export_category("Gathering Animation")
@export_range(0.5, 10.0, 0.1) var gathering_speed := 4.5
@export_range(0.0, 10.0, 0.5) var gathering_bob_amount := 2.0
@export_range(0.0, 15.0, 0.5) var gathering_tilt_degrees := 4.0

var is_gathering := false
var gathering_time := 0.0
var gathering_target_position := Vector2.ZERO
var resting_position := Vector2.ZERO

@onready var player: Player = get_parent()
@onready var footstep_sound: AudioStreamPlayer = (
	$"../FootstepSound"
)

func _ready() -> void:
	resting_position = position
	
	frame_changed.connect(
		_on_animation_frame_changed
	)
	

var last_facing: Facing = Facing.DOWN
var last_side_was_left: bool = false


func _process(delta: float) -> void:
	var movement := player.velocity

	if (
		is_gathering
		and movement.length_squared() <= 0.0
	):
		_update_gathering_animation(delta)
		return

	_reset_gathering_transform()

	if movement.length_squared() > 0.0:
		_update_walking_animation(movement)
	else:
		_update_idle_animation()


func _update_walking_animation(
	movement: Vector2
) -> void:
	if absf(movement.x) > absf(movement.y):
		last_facing = Facing.SIDE
		last_side_was_left = movement.x < 0.0

		flip_h = last_side_was_left
		_play_if_changed("walk_side")
		return

	flip_h = false

	if movement.y < 0.0:
		last_facing = Facing.UP
		_play_if_changed("walk_up")
	else:
		last_facing = Facing.DOWN
		_play_if_changed("walk_down")


func _update_idle_animation() -> void:
	match last_facing:
		Facing.DOWN:
			flip_h = false
			_play_if_changed("idle_down")

		Facing.UP:
			flip_h = false
			_play_if_changed("idle_up")

		Facing.SIDE:
			flip_h = last_side_was_left
			_play_if_changed("idle_side")


func _play_if_changed(
	animation_name: StringName
) -> void:
	if animation == animation_name:
		return

	play(animation_name)

	if String(animation_name).begins_with("walk_"):
		_play_footstep()

func _on_animation_frame_changed() -> void:
	var animation_text := String(animation)

	if not animation_text.begins_with("walk_"):
		return

	if frame != 0:
		return
	
	_play_footstep()

func _play_footstep() -> void:
	if footstep_sound.stream == null:
		return

	var current_time_ms := Time.get_ticks_msec()

	if current_time_ms - last_footstep_time_ms < 120:
		return

	last_footstep_time_ms = current_time_ms

	footstep_sound.pitch_scale = randf_range(
		0.94,
		1.06
	)

	footstep_sound.play()

func start_gathering(
	target_position: Vector2
) -> void:
	if (
		is_gathering
		and gathering_target_position
			== target_position
	):
		return

	is_gathering = true
	gathering_target_position = target_position
	gathering_time = 0.0

	_update_facing_toward(
		gathering_target_position
	)


func stop_gathering() -> void:
	is_gathering = false
	gathering_time = 0.0
	_reset_gathering_transform()


func _update_gathering_animation(delta: float) -> void:
	gathering_time += delta

	_update_facing_toward(
		gathering_target_position
	)
	_update_idle_animation()

	var motion := sin(
		gathering_time
		* gathering_speed
		* TAU
	)

	position = (
		resting_position
		+ Vector2(
			0.0,
			absf(motion) * gathering_bob_amount
		)
	)

	rotation = deg_to_rad(
		motion * gathering_tilt_degrees
	)


func _update_facing_toward(
	target_position: Vector2
) -> void:
	var direction := (
		target_position
		- player.global_position
	)

	if absf(direction.x) > absf(direction.y):
		last_facing = Facing.SIDE
		last_side_was_left = direction.x < 0.0
	elif direction.y < 0.0:
		last_facing = Facing.UP
	else:
		last_facing = Facing.DOWN


func _reset_gathering_transform() -> void:
	position = resting_position
	rotation = 0.0
