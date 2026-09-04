class_name ForestLife
extends Node2D


enum LifeType {
	BUTTERFLY,
	FIREFLY,
	LEAF
}


@export_category("Wildlife Counts")
@export_range(0, 100) var butterfly_count := 24
@export_range(0, 150) var firefly_count := 36
@export_range(0, 100) var drifting_leaf_count := 28

@export_category("Wildlife Colours")
@export var butterfly_yellow := Color("#f2d479")
@export var butterfly_blue := Color("#83a8c9")
@export var firefly_color := Color("#dff27a")
@export var leaf_green := Color("#567d3d")
@export var leaf_brown := Color("#9a6841")
@export var leaf_gold := Color("#b99648")

@export_category("Habitat Placement")
@export_range(0.0, 1.0, 0.05) var habitat_preference := 0.85
@export_range(0.0, 96.0, 1.0) var habitat_spread := 42.0

var life_points: Array[Dictionary] = []
var random := RandomNumberGenerator.new()

var current_phase := "morning"
var animation_time := 0.0


func _ready() -> void:
	z_index = 2
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func generate_life(
	seed_value: int,
	map_width: int,
	map_height: int,
	tile_size: int,
	butterfly_habitats: Array[Vector2],
	firefly_habitats: Array[Vector2]
) -> void:
	life_points.clear()
	random.seed = seed_value + 148_217

	var world_size := Vector2(
		map_width * tile_size,
		map_height * tile_size
	)

	for index in range(butterfly_count):
		_add_life_point(
			LifeType.BUTTERFLY,
			world_size,
			butterfly_habitats
		)

	for index in range(firefly_count):
		_add_life_point(
			LifeType.FIREFLY,
			world_size,
			firefly_habitats
		)
	
	for index in range(drifting_leaf_count):
		_add_life_point(
			LifeType.LEAF,
			world_size,
			[]
		)

	queue_redraw()


func _add_life_point(
	life_type: LifeType,
	world_size: Vector2,
	preferred_habitats: Array[Vector2]
) -> void:
	var base_position: Vector2

	var use_habitat := (
		not preferred_habitats.is_empty()
		and random.randf() < habitat_preference
	)

	if use_habitat:
		var habitat_index := random.randi_range(
			0,
			preferred_habitats.size() - 1
		)

		var habitat_position: Vector2 = (
			preferred_habitats[habitat_index]
		)

		var offset_angle := random.randf_range(
			0.0,
			TAU
		)

		var offset_distance := random.randf_range(
			6.0,
			habitat_spread
		)

		base_position = (
			habitat_position
			+ Vector2.RIGHT.rotated(offset_angle)
				* offset_distance
		)
	else:
		base_position = Vector2(
			random.randf_range(
				32.0,
				world_size.x - 32.0
			),
			random.randf_range(
				64.0,
				world_size.y - 32.0
			)
		)

	base_position.x = clampf(
		base_position.x,
		32.0,
		world_size.x - 32.0
	)

	base_position.y = clampf(
		base_position.y,
		64.0,
		world_size.y - 32.0
	)

	life_points.append({
		"type": life_type,
		"base_position": base_position,
		"phase_offset": random.randf_range(0.0, TAU),
		"speed": random.randf_range(0.65, 1.25),
		"variant": random.randi_range(0, 1)
	})


func set_phase(phase: String) -> void:
	current_phase = phase.to_lower()
	queue_redraw()


func _process(delta: float) -> void:
	animation_time += delta
	queue_redraw()


func _draw() -> void:
	var show_butterflies := (
		current_phase == "morning"
		or current_phase == "afternoon"
	)

	var show_fireflies := (
		current_phase == "evening"
		or current_phase == "night"
	)
	
	var show_leaves := (
		current_phase == "morning"
		or current_phase == "afternoon"
		or current_phase == "evening"
	)

	for life_point in life_points:
		var life_type := int(
			life_point["type"]
		)

		if (
			life_type == LifeType.BUTTERFLY
			and show_butterflies
		):
			_draw_butterfly(life_point)
		elif (
			life_type == LifeType.FIREFLY
			and show_fireflies
		):
			_draw_firefly(life_point)
		elif (
			life_type == LifeType.LEAF
			and show_leaves
		):
			_draw_leaf(life_point)

	

func _draw_butterfly(
	life_point: Dictionary
) -> void:
	var base_position := (
		life_point["base_position"] as Vector2
	)

	var phase_offset := float(
		life_point["phase_offset"]
	)

	var speed := float(
		life_point["speed"]
	)

	var variant := int(
		life_point["variant"]
	)

	var motion_time := (
		animation_time * speed
		+ phase_offset
	)

	var draw_position := (
		base_position
		+ Vector2(
			sin(motion_time) * 10.0,
			cos(motion_time * 0.7) * 6.0
		)
	).round()

	var selected_color := butterfly_yellow

	if variant == 1:
		selected_color = butterfly_blue

	var wing_open := (
		sin(motion_time * 7.0) > 0.0
	)

	if wing_open:
		draw_rect(
			Rect2(
				draw_position + Vector2(-3.0, -1.0),
				Vector2(2.0, 2.0)
			),
			selected_color
		)

		draw_rect(
			Rect2(
				draw_position + Vector2(2.0, -1.0),
				Vector2(2.0, 2.0)
			),
			selected_color
		)
	else:
		draw_rect(
			Rect2(
				draw_position + Vector2(-1.0, -2.0),
				Vector2(1.0, 3.0)
			),
			selected_color
		)

		draw_rect(
			Rect2(
				draw_position + Vector2(1.0, -2.0),
				Vector2(1.0, 3.0)
			),
			selected_color
		)

	draw_rect(
		Rect2(
			draw_position,
			Vector2(1.0, 2.0)
		),
		Color("#443729")
	)

func _draw_firefly(
	life_point: Dictionary
) -> void:
	var base_position := (
		life_point["base_position"] as Vector2
	)

	var phase_offset := float(
		life_point["phase_offset"]
	)

	var speed := float(
		life_point["speed"]
	)

	var motion_time := (
		animation_time * speed
		+ phase_offset
	)

	var draw_position := (
		base_position
		+ Vector2(
			sin(motion_time * 0.8) * 7.0,
			cos(motion_time) * 5.0
		)
	).round()

	var brightness := (
		sin(motion_time * 2.4) * 0.5
		+ 0.5
	)

	var glow_color := firefly_color
	glow_color.a = 0.08 + brightness * 0.18

	var center_color := firefly_color
	center_color.a = 0.4 + brightness * 0.6

	draw_circle(
		draw_position,
		4.0,
		glow_color
	)

	draw_circle(
		draw_position,
		1.0,
		center_color
	)

func _draw_leaf(
	life_point: Dictionary
) -> void:
	var base_position := (
		life_point["base_position"] as Vector2
	)

	var phase_offset := float(
		life_point["phase_offset"]
	)

	var speed := float(
		life_point["speed"]
	)

	var variant := int(
		life_point["variant"]
	)

	var motion_time := (
		animation_time * speed
		+ phase_offset
	)

	var drift_cycle := fposmod(
		motion_time,
		TAU
	)

	var horizontal_drift := (
		sin(motion_time * 0.65) * 18.0
		+ drift_cycle * 5.0
	)

	var vertical_drift := (
		drift_cycle * 7.0
		+ sin(motion_time * 1.4) * 3.0
	)

	var draw_position := (
		base_position
		+ Vector2(
			horizontal_drift,
			vertical_drift
		)
	)

	var selected_color := leaf_green

	if variant == 1:
		selected_color = leaf_brown

	if current_phase == "evening":
		selected_color = leaf_gold.darkened(0.15)

	var leaf_direction := Vector2(
		3.0,
		sin(motion_time * 2.0) * 2.0
	)

	draw_line(
		draw_position,
		draw_position + leaf_direction,
		selected_color,
		2.0
	)

	draw_circle(
		draw_position + leaf_direction,
		1.2,
		selected_color.lightened(0.12)
	)
