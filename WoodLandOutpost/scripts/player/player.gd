class_name Player
extends CharacterBody2D


@export_category("Movement")
@export var movement_speed: float = 180.0

@export_category("Map Boundaries")
@export var minimum_position := Vector2(10.0, 14.0)
@export var maximum_position := Vector2(1270.0, 690.0)

var movement_enabled: bool = true

func _physics_process(_delta: float) -> void:
	
	if not movement_enabled:
		velocity = Vector2.ZERO
		return
	
	var input_direction := Input.get_vector(
		"move_left",
		"move_right",
		"move_up",
		"move_down"
	)

	velocity = input_direction * movement_speed

	move_and_slide()
	_keep_inside_map()


func _keep_inside_map() -> void:
	global_position.x = clampf(
		global_position.x,
		minimum_position.x,
		maximum_position.x
	)

	global_position.y = clampf(
		global_position.y,
		minimum_position.y,
		maximum_position.y
	)


func set_movement_enabled(enabled: bool) -> void:
	movement_enabled = enabled

	if not movement_enabled:
		velocity = Vector2.ZERO
