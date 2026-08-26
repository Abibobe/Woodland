class_name Camp
extends InteractionTarget


signal stage_changed(new_stage: CampStage)


enum CampStage {
	SITE,
	CAMPFIRE,
	FOUNDATION,
	CABIN
}


@export var current_stage: CampStage = CampStage.SITE:
	set(value):
		current_stage = value
		queue_redraw()


func _ready() -> void:
	queue_redraw()


func get_interaction_text() -> String:
	if current_stage == CampStage.CABIN:
		return "E — Inspect cabin"

	return "E — Inspect camp"


func interact() -> Dictionary:
	return {
		"action": "camp_opened",
		"camp": self
	}


func get_next_stage_name() -> String:
	match current_stage:
		CampStage.SITE:
			return "Campfire"

		CampStage.CAMPFIRE:
			return "Foundation"

		CampStage.FOUNDATION:
			return "Cabin"

		CampStage.CABIN:
			return "Complete"

	return "Unknown"


func get_next_stage_cost() -> Dictionary:
	match current_stage:
		CampStage.SITE:
			return {
				ResourceNode.ResourceType.WOOD: 5
			}

		CampStage.CAMPFIRE:
			return {
				ResourceNode.ResourceType.WOOD: 10,
				ResourceNode.ResourceType.STONE: 5
			}

		CampStage.FOUNDATION:
			return {
				ResourceNode.ResourceType.WOOD: 20,
				ResourceNode.ResourceType.STONE: 10
			}

	return {}


func advance_construction() -> bool:
	if current_stage == CampStage.CABIN:
		return false

	current_stage += 1
	stage_changed.emit(current_stage)

	return true


func _draw() -> void:
	match current_stage:
		CampStage.SITE:
			_draw_site()

		CampStage.CAMPFIRE:
			_draw_campfire()

		CampStage.FOUNDATION:
			_draw_foundation()

		CampStage.CABIN:
			_draw_cabin()


func _draw_site() -> void:
	draw_dashed_line(
		Vector2(-30, -24),
		Vector2(30, -24),
		Color("#E5D4A8"),
		2.0,
		4.0
	)

	draw_dashed_line(
		Vector2(30, -24),
		Vector2(30, 16),
		Color("#E5D4A8"),
		2.0,
		4.0
	)

	draw_dashed_line(
		Vector2(30, 16),
		Vector2(-30, 16),
		Color("#E5D4A8"),
		2.0,
		4.0
	)

	draw_dashed_line(
		Vector2(-30, 16),
		Vector2(-30, -24),
		Color("#E5D4A8"),
		2.0,
		4.0
	)


func _draw_campfire() -> void:
	draw_circle(Vector2.ZERO, 13, Color("#6F6255"))
	draw_circle(Vector2.ZERO, 8, Color("#E88632"))
	draw_circle(Vector2(0, -4), 5, Color("#F5C451"))


func _draw_foundation() -> void:
	draw_rect(
		Rect2(-30, -24, 60, 40),
		Color("#706152")
	)

	draw_rect(
		Rect2(-24, -18, 48, 28),
		Color("#94785A")
	)


func _draw_cabin() -> void:
	draw_rect(
		Rect2(-30, -24, 60, 40),
		Color("#815530")
	)

	var roof := PackedVector2Array([
		Vector2(-36, -24),
		Vector2(0, -50),
		Vector2(36, -24)
	])

	draw_colored_polygon(
		roof,
		Color("#493B32")
	)

	draw_rect(
		Rect2(-7, -5, 14, 21),
		Color("#3D2A20")
	)

	draw_rect(
		Rect2(-22, -13, 10, 10),
		Color("#B8D5D1")
	)
