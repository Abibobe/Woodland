class_name BuildableCampfire
extends StaticBody2D


@export_category("Light")
@export var light_color := Color("#ffb45f")

@export_range(0.1, 2.0, 0.05)
var light_energy := 0.85

@export_range(32.0, 256.0, 1.0)
var light_texture_size := 128.0


@onready var warm_light: PointLight2D = (
	$WarmLight
)


var animation_time := 0.0


func _ready() -> void:
	texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)

	_create_light_texture()
	queue_redraw()


func _process(delta: float) -> void:
	animation_time += delta

	var flicker := (
		sin(animation_time * 7.0) * 0.05
		+ sin(animation_time * 11.0) * 0.03
	)

	warm_light.energy = (
		light_energy + flicker
	)

	queue_redraw()


func _create_light_texture() -> void:
	var gradient := Gradient.new()

	gradient.colors = PackedColorArray([
		Color.WHITE,
		Color(1.0, 1.0, 1.0, 0.0)
	])

	var light_texture := GradientTexture2D.new()

	light_texture.gradient = gradient
	light_texture.width = roundi(
		light_texture_size
	)

	light_texture.height = roundi(
		light_texture_size
	)

	light_texture.fill = (
		GradientTexture2D.FILL_RADIAL
	)

	light_texture.fill_from = Vector2(
		0.5,
		0.5
	)

	light_texture.fill_to = Vector2(
		1.0,
		0.5
	)

	warm_light.texture = light_texture
	warm_light.color = light_color
	warm_light.energy = light_energy


func _draw() -> void:
	# Ground shadow.
	draw_pixel_ellipse(
		Vector2(0.0, 5.0),
		Vector2(16.0, 6.0),
		Color(0.04, 0.06, 0.04, 0.30)
	)

	# Stone ring.
	var stone_positions := [
		Vector2(-10.0, 2.0),
		Vector2(-6.0, 7.0),
		Vector2(0.0, 8.0),
		Vector2(6.0, 7.0),
		Vector2(10.0, 2.0),
		Vector2(7.0, -2.0),
		Vector2(-7.0, -2.0)
	]

	for stone_position in stone_positions:
		draw_circle(
			stone_position,
			3.0,
			Color("#777c74")
		)

	# Crossed logs.
	draw_line(
		Vector2(-7.0, 5.0),
		Vector2(7.0, -1.0),
		Color("#62422b"),
		4.0
	)

	draw_line(
		Vector2(-7.0, -1.0),
		Vector2(7.0, 5.0),
		Color("#7c5030"),
		4.0
	)

	var flame_offset := sin(
		animation_time * 8.0
	) * 1.0

	# Outer flame.
	var outer_flame := PackedVector2Array([
		Vector2(-6.0, 2.0),
		Vector2(-3.0, -8.0),
		Vector2(0.0, -14.0 + flame_offset),
		Vector2(3.0, -7.0),
		Vector2(6.0, 2.0)
	])

	draw_colored_polygon(
		outer_flame,
		Color("#e86f32")
	)

	# Inner flame.
	var inner_flame := PackedVector2Array([
		Vector2(-3.0, 2.0),
		Vector2(0.0, -8.0 - flame_offset),
		Vector2(3.0, 2.0)
	])

	draw_colored_polygon(
		inner_flame,
		Color("#ffd36b")
	)


func draw_pixel_ellipse(
	center: Vector2,
	radius: Vector2,
	color: Color
) -> void:
	var points := PackedVector2Array()
	var point_count := 24

	for point_index in range(point_count):
		var angle := (
			TAU
			* float(point_index)
			/ float(point_count)
		)

		points.append(
			center + Vector2(
				cos(angle) * radius.x,
				sin(angle) * radius.y
			)
		)

	draw_colored_polygon(
		points,
		color
	)
