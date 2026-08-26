class_name HUD
extends Control


@onready var day_label: Label = (
	$TopBar/MarginContainer/ResourceRow/DayLabel
)

@onready var wood_label: Label = (
	$TopBar/MarginContainer/ResourceRow/WoodLabel
)

@onready var stone_label: Label = (
	$TopBar/MarginContainer/ResourceRow/StoneLabel
)

@onready var food_label: Label = (
	$TopBar/MarginContainer/ResourceRow/FoodLabel
)


func set_resource_amount(
	resource_type: int,
	amount: int
) -> void:
	match resource_type:
		ResourceNode.ResourceType.WOOD:
			wood_label.text = "Wood %s" % amount

		ResourceNode.ResourceType.STONE:
			stone_label.text = "Stone %s" % amount

		ResourceNode.ResourceType.FOOD:
			food_label.text = "Food %s" % amount


func set_day(day: int) -> void:
	day_label.text = "Day %s" % day
