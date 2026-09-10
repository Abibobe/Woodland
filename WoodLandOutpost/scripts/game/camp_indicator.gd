class_name CampIndicator
extends Control



@export_category("World References")
@export var player: Node2D
@export var camp: Node2D

@export_category("Screen Placement")
@export var side_margin := 42.0
@export var top_margin := 70.0
@export var bottom_margin := 42.0

@export_range(1, 128) var tile_size := 32

@onready var distance_label: Label = $DistanceLabel

const ARROW_COLOR := Color("#f2d479")
const ARROW_OUTLINE_COLOR := Color("#583f24")


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = Vector2(28.0, 28.0)
	pivot_offset = size / 2.0
	hide()

	queue_redraw()


func _process(_delta: float) -> void:
	if not is_instance_valid(player):
		hide()
		return

	if not is_instance_valid(camp):
		hide()
		return

	var viewport_size := (
		get_viewport().get_visible_rect().size
	)

	var camp_screen_position := (
		get_viewport().get_canvas_transform()
		* camp.global_position
	)

	var visible_area := Rect2(
		Vector2(
			side_margin,
			top_margin
		),
		Vector2(
			viewport_size.x - side_margin * 2.0,
			viewport_size.y
				- top_margin
				- bottom_margin
		)
	)

	if visible_area.has_point(camp_screen_position):
		hide()
		return

	var distance_in_tiles := roundi(
		player.global_position.distance_to(
			camp.global_position
		) / float(tile_size)
	)

	distance_label.text = "%d feet" % distance_in_tiles

	show()

	var screen_center := viewport_size / 2.0
	var direction := (
		camp_screen_position
		- screen_center
	).normalized()

	var available_half_size := Vector2(
		visible_area.size.x / 2.0,
		visible_area.size.y / 2.0
	)

	var horizontal_scale := INF
	var vertical_scale := INF

	if absf(direction.x) > 0.001:
		horizontal_scale = (
			available_half_size.x
			/ absf(direction.x)
		)

	if absf(direction.y) > 0.001:
		vertical_scale = (
			available_half_size.y
			/ absf(direction.y)
		)

	var edge_distance := minf(
		horizontal_scale,
		vertical_scale
	)

	var indicator_center := (
		visible_area.get_center()
		+ direction * edge_distance
	)

	position = indicator_center - size / 2.0
	rotation = direction.angle()


func _draw() -> void:
	var arrow_points := PackedVector2Array([
		Vector2(13.0, 0.0),
		Vector2(-9.0, -9.0),
		Vector2(-5.0, 0.0),
		Vector2(-9.0, 9.0)
	])

	draw_colored_polygon(
		arrow_points,
		ARROW_COLOR
	)

	var outline_points := PackedVector2Array([
		Vector2(13.0, 0.0),
		Vector2(-9.0, -9.0),
		Vector2(-5.0, 0.0),
		Vector2(-9.0, 9.0),
		Vector2(13.0, 0.0)
	])

	draw_polyline(
		outline_points,
		ARROW_OUTLINE_COLOR,
		2.0,
		false
	)
