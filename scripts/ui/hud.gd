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

@onready var interaction_prompt: PanelContainer = (
	$InteractionPrompt
)

@onready var interaction_prompt_label: Label = (
	$InteractionPrompt/MarginContainer/
	PromptRow/PromptLabel
)

@onready var top_bar: PanelContainer = $TopBar

@onready var resource_gain_popup: Label = (
	$ResourceGainPopup
)

var resource_label_tweens: Dictionary = {}

var resource_gain_tween: Tween

var interaction_prompt_tween: Tween

func set_resource_amount(
	resource_type: int,
	amount: int
) -> void:
	var target_label: Label = null
	var resource_name := ""

	match resource_type:
		ResourceTypes.Type.WOOD:
			target_label = wood_label
			resource_name = "Wood"

		ResourceTypes.Type.STONE:
			target_label = stone_label
			resource_name = "Stone"

		ResourceTypes.Type.FOOD:
			target_label = food_label
			resource_name = "Food"

	if target_label == null:
		return

	target_label.text = "%s %s" % [
		resource_name,
		amount
	]

	_flash_resource_label(target_label)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	get_viewport().size_changed.connect(_apply_layout)
	call_deferred("_apply_layout")
	interaction_prompt.modulate.a = 0.0
	interaction_prompt.hide()


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
	var clean_text := text

	if clean_text.begins_with("Press E to "):
		clean_text = clean_text.trim_prefix(
			"Press E to "
		)

	interaction_prompt_label.text = (
		clean_text.capitalize()
	)

	if interaction_prompt_tween != null:
		interaction_prompt_tween.kill()

	interaction_prompt.show()
	interaction_prompt.modulate.a = 0.0

	interaction_prompt_tween = create_tween()

	interaction_prompt_tween.tween_property(
		interaction_prompt,
		"modulate:a",
		1.0,
		0.12
	)


func hide_interaction_prompt() -> void:
	if not interaction_prompt.visible:
		return

	if interaction_prompt_tween != null:
		interaction_prompt_tween.kill()

	interaction_prompt_tween = create_tween()

	interaction_prompt_tween.tween_property(
		interaction_prompt,
		"modulate:a",
		0.0,
		0.1
	)

	interaction_prompt_tween.tween_callback(
		interaction_prompt.hide
	)
	
func show_resource_gain(
	text: String,
	screen_position: Vector2
	) -> void:
	if resource_gain_tween != null:
		resource_gain_tween.kill()

	resource_gain_popup.text = text
	resource_gain_popup.size = Vector2(120.0, 24.0)

	var start_position := Vector2(
		screen_position.x - 60.0,
		screen_position.y - 42.0
	)

	resource_gain_popup.position = start_position
	resource_gain_popup.modulate.a = 1.0
	resource_gain_popup.show()

	resource_gain_tween = create_tween()

	resource_gain_tween.tween_property(
		resource_gain_popup,
		"position",
		start_position + Vector2(0.0, -20.0),
		0.65
	)

	resource_gain_tween.parallel().tween_property(
		resource_gain_popup,
		"modulate:a",
		0.0,
		0.5
	).set_delay(0.15)

	resource_gain_tween.chain().tween_callback(
		resource_gain_popup.hide
	)


func _flash_resource_label(
	target_label: Label
) -> void:
	var existing_tween: Tween = (
		resource_label_tweens.get(target_label)
	)

	if existing_tween != null:
		existing_tween.kill()

	target_label.modulate = Color("#f2d479")

	var new_tween := create_tween()

	resource_label_tweens[target_label] = new_tween

	new_tween.tween_property(
		target_label,
		"modulate",
		Color.WHITE,
		0.25
	)

	new_tween.tween_callback(
		func() -> void:
			resource_label_tweens.erase(target_label)
	)
