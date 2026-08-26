class_name ResourceNode
extends StaticBody2D


enum ResourceType {
	WOOD,
	STONE,
	FOOD
}


@export var resource_type: ResourceType = ResourceType.WOOD:
	set(value):
		resource_type = value
		queue_redraw()

@export_range(1, 10) var resource_amount: int = 3


func _ready() -> void:
	queue_redraw()


func get_resource_name() -> String:
	match resource_type:
		ResourceType.WOOD:
			return "Wood"

		ResourceType.STONE:
			return "Stone"

		ResourceType.FOOD:
			return "Food"

	return "Unknown"

func gather(requested_amount: int = 1) -> int:
	if requested_amount <= 0:
		return 0

	var gathered_amount := mini(
		requested_amount,
		resource_amount
	)

	resource_amount -= gathered_amount

	if resource_amount <= 0:
		queue_free()

	return gathered_amount

func _draw() -> void:
	match resource_type:
		ResourceType.WOOD:
			_draw_tree()

		ResourceType.STONE:
			_draw_rock()

		ResourceType.FOOD:
			_draw_berry_bush()


func _draw_tree() -> void:
	draw_rect(
		Rect2(-5, -20, 10, 24),
		Color("#6B4423")
	)

	draw_circle(
		Vector2(0, -24),
		17,
		Color("#285943")
	)

	draw_circle(
		Vector2(-10, -18),
		12,
		Color("#347052")
	)

	draw_circle(
		Vector2(10, -18),
		12,
		Color("#347052")
	)


func _draw_rock() -> void:
	var rock_shape := PackedVector2Array([
		Vector2(-14, 4),
		Vector2(-11, -9),
		Vector2(-3, -15),
		Vector2(10, -11),
		Vector2(15, 2),
		Vector2(8, 8),
		Vector2(-8, 8)
	])

	draw_colored_polygon(
		rock_shape,
		Color("#70777D")
	)


func _draw_berry_bush() -> void:
	draw_circle(
		Vector2.ZERO,
		15,
		Color("#3E7045")
	)

	draw_circle(Vector2(-7, -5), 3, Color("#A83E5B"))
	draw_circle(Vector2(6, -7), 3, Color("#A83E5B"))
	draw_circle(Vector2(3, 5), 3, Color("#A83E5B"))
