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

@onready var interaction_prompt: Label = $InteractionPrompt

@onready var top_bar: PanelContainer = $TopBar

func set_resource_amount(
	resource_type: int,
	amount: int
) -> void:
	match resource_type:
		ResourceTypes.Type.WOOD:
			wood_label.text = "Wood %s" % amount

		ResourceTypes.Type.STONE:
			stone_label.text = "Stone %s" % amount

		ResourceTypes.Type.FOOD:
			food_label.text = "Food %s" % amount


func _ready() -> void:
	get_viewport().size_changed.connect(_apply_layout)
	call_deferred("_apply_layout")



func set_day(
	day: int,
	phase: String
) -> void:
	day_label.text = "Day %s · %s" % [
		day,
		phase
	]

func _apply_layout() -> void:
	var viewport_size := get_viewport().get_visible_rect().size

	set_anchors_preset(Control.PRESET_TOP_LEFT)
	position = Vector2.ZERO
	size = viewport_size

	top_bar.set_anchors_preset(Control.PRESET_TOP_LEFT)
	top_bar.position = Vector2.ZERO
	top_bar.size = Vector2(viewport_size.x, 42.0)

	interaction_prompt.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)

	interaction_prompt.size = Vector2(240.0, 36.0)

	interaction_prompt.position = Vector2(
		(viewport_size.x - interaction_prompt.size.x) / 2.0,
		viewport_size.y - 58.0
	)
	
func show_interaction_prompt(text: String) -> void:
	interaction_prompt.text = text
	interaction_prompt.show()


func hide_interaction_prompt() -> void:
	interaction_prompt.hide()
