class_name CampPlacementController
extends Node2D


signal placement_confirmed(
	world_position: Vector2
)

@export_flags_2d_physics
var placement_obstacle_mask := 1

@export_range(4, 30, 1)
var maximum_scouting_distance := 12
var scouting_origin := Vector2.ZERO

@export_category("References")
@export var player: CharacterBody2D
@export var existing_camp: StaticBody2D

@export_category("World")
@export var world_size := Vector2(
	2304.0,
	1408.0
)

@export_range(8, 128, 1)
var tile_size := 32

@export_range(0.0, 256.0, 1.0)
var world_margin := 64.0


const CAMP_SHAPE_SIZE := Vector2(
	64.0,
	48.0
)

const CAMP_SHAPE_OFFSET := Vector2(
	0.0,
	-8.0
)

const VALID_COLOR := Color(
	0.35,
	0.85,
	0.45,
	0.35
)

const INVALID_COLOR := Color(
	0.95,
	0.30,
	0.28,
	0.38
)

const VALID_BORDER := Color("#8fe18f")
const INVALID_BORDER := Color("#f07872")


var placement_active := false
var placement_valid := false
var placement_available := false

var query_shape := RectangleShape2D.new()


func _ready() -> void:
	z_index = 100
	texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)

	query_shape.size = CAMP_SHAPE_SIZE

	hide()
	set_process(false)


func begin_placement() -> void:
	if not placement_available:
		return

	placement_active = true

	show()
	set_process(true)

	_update_preview_position()
	_update_placement_validity()
	queue_redraw()


func cancel_placement() -> void:
	placement_active = false

	hide()
	set_process(false)


func _process(_delta: float) -> void:
	if not placement_active:
		return

	_update_preview_position()
	_update_placement_validity()
	queue_redraw()


func _input(
	event: InputEvent
) -> void:
	if event.is_echo():
		return

	if not placement_available:
		return

	if event.is_action_pressed(
		"toggle_build_mode"
	):
		if placement_active:
			cancel_placement()
		else:
			begin_placement()

		get_viewport().set_input_as_handled()
		return

	if not placement_active:
		return

	if event.is_action_pressed("ui_cancel"):
		cancel_placement()
		get_viewport().set_input_as_handled()
		return

	if not event is InputEventMouseButton:
		return

	var mouse_event := (
		event as InputEventMouseButton
	)

	if (
		mouse_event.button_index
		!= MOUSE_BUTTON_LEFT
	):
		return

	if not mouse_event.pressed:
		return

	if not placement_valid:
		return

	var confirmed_position := global_position

	# The unique Camp Kit is consumed here, before the
	# GameManager receives the placement request.
	placement_available = false
	cancel_placement()
	set_process_input(false)

	placement_confirmed.emit(
		confirmed_position
	)

	get_viewport().set_input_as_handled()


func _update_preview_position() -> void:
	var mouse_world_position := (
		get_global_mouse_position()
	)

	global_position = Vector2(
		roundf(
			mouse_world_position.x
			/ float(tile_size)
		) * tile_size,
		roundf(
			mouse_world_position.y
			/ float(tile_size)
		) * tile_size
	)


func _update_placement_validity() -> void:
	placement_valid = (
		_is_inside_world()
		and _is_inside_scouting_area()
		and not _overlaps_obstacle()
	)


func _is_inside_world() -> bool:
	var camp_rect := Rect2(
		global_position
			+ CAMP_SHAPE_OFFSET
			- CAMP_SHAPE_SIZE / 2.0,
		CAMP_SHAPE_SIZE
	)

	var permitted_world := Rect2(
		Vector2(
			world_margin,
			world_margin
		),
		world_size - Vector2.ONE
			* world_margin * 2.0
	)

	return (
		permitted_world.encloses(
			camp_rect
		)
	)


func _overlaps_obstacle() -> bool:
	var world := get_world_2d()

	if world == null:
		return true

	var query := (
		PhysicsShapeQueryParameters2D.new()
	)

	query.shape = query_shape

	query.transform = Transform2D(
		0.0,
		global_position + CAMP_SHAPE_OFFSET
	)

	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask = placement_obstacle_mask

	var exclusions: Array[RID] = []

	if is_instance_valid(player):
		exclusions.append(
			player.get_rid()
		)

	if is_instance_valid(existing_camp):
		exclusions.append(
			existing_camp.get_rid()
		)

	query.exclude = exclusions

	var collisions := (
		world.direct_space_state
		.intersect_shape(
			query,
			1
		)
	)

	return not collisions.is_empty()


func _draw() -> void:
	if not placement_active:
		return

	var preview_rect := Rect2(
		CAMP_SHAPE_OFFSET
			- CAMP_SHAPE_SIZE / 2.0,
		CAMP_SHAPE_SIZE
	)

	var fill_color := (
		VALID_COLOR
		if placement_valid
		else INVALID_COLOR
	)

	var border_color := (
		VALID_BORDER
		if placement_valid
		else INVALID_BORDER
	)

	draw_rect(
		preview_rect,
		fill_color,
		true
	)

	draw_rect(
		preview_rect,
		border_color,
		false,
		2.0
	)

	draw_dashed_line(
		Vector2(-30.0, -24.0),
		Vector2(30.0, -24.0),
		border_color,
		2.0,
		4.0
	)

	draw_dashed_line(
		Vector2(30.0, -24.0),
		Vector2(30.0, 16.0),
		border_color,
		2.0,
		4.0
	)

	draw_dashed_line(
		Vector2(30.0, 16.0),
		Vector2(-30.0, 16.0),
		border_color,
		2.0,
		4.0
	)

	draw_dashed_line(
		Vector2(-30.0, 16.0),
		Vector2(-30.0, -24.0),
		border_color,
		2.0,
		4.0
	)

func configure(
	new_world_size: Vector2,
	new_scouting_origin: Vector2
) -> void:
	world_size = new_world_size
	scouting_origin = new_scouting_origin

func _is_inside_scouting_area() -> bool:
	var maximum_distance_pixels := (
		maximum_scouting_distance
		* float(tile_size)
	)

	return (
		global_position.distance_to(
			scouting_origin
		)
		<= maximum_distance_pixels
	)

func enable_placement() -> void:
	placement_available = true
	set_process_input(true)


func lock_placement() -> void:
	placement_available = false
	cancel_placement()
	set_process_input(false)
