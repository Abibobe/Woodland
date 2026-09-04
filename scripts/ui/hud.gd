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
	$InteractionPrompt/MarginContainer/PromptRow/PromptLabel
)

@onready var top_bar: PanelContainer = $TopBar

@onready var resource_gain_popup: Label = (
	$ResourceGainPopup
)

@onready var backpack_label: Label = (
	$TopBar/MarginContainer/ResourceRow/BackpackLabel
)

@onready var delivery_popup: PanelContainer = (
	$DeliveryPopup
)

@onready var wood_delivery_label: Label = (
	$DeliveryPopup/MarginContainer/
	DeliveryContent/WoodDeliveryLabel
)

@onready var stone_delivery_label: Label = (
	$DeliveryPopup/MarginContainer/
	DeliveryContent/StoneDeliveryLabel
)

@onready var food_delivery_label: Label = (
	$DeliveryPopup/MarginContainer/
	DeliveryContent/FoodDeliveryLabel
)

@onready var milestone_popup: PanelContainer = (
	$MilestonePopup
)

@onready var milestone_label: Label = (
	$MilestonePopup/MarginContainer/MilestoneLabel
)

@onready var tutorial_hint: PanelContainer = (
	$TutorialHint
)

@onready var tutorial_label: Label = (
	$TutorialHint/MarginContainer/TutorialLabel
)

var tutorial_hint_tween: Tween

var delivery_tween: Tween

var milestone_tween: Tween


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
	delivery_popup.hide()
	milestone_popup.hide()
	tutorial_hint.hide()



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
	delivery_popup.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)

	delivery_popup.size = Vector2(
		220.0,
		100.0
	)

	delivery_popup.position = Vector2(
		(viewport_size.x - delivery_popup.size.x) / 2.0,
		viewport_size.y - 180.0
	)
	delivery_popup.set_anchors_preset(
		Control.PRESET_TOP_LEFT
	)

	delivery_popup.size = Vector2(
		220.0,
		100.0
	)

	delivery_popup.position = Vector2(
		(viewport_size.x - delivery_popup.size.x) / 2.0,
		viewport_size.y - 180.0
	)
	
	milestone_popup.size = Vector2(
		460.0,
		70.0
	)

	milestone_popup.position = Vector2(
		(viewport_size.x - milestone_popup.size.x) / 2.0,
		76.0
	)

	milestone_popup.pivot_offset = (
		milestone_popup.size / 2.0
	)
	
	
	tutorial_hint.size = Vector2(
		380.0,
		54.0
	)

	tutorial_hint.position = Vector2(
		(viewport_size.x - tutorial_hint.size.x) / 2.0,
		154.0
	)

	tutorial_hint.pivot_offset = (
		tutorial_hint.size / 2.0
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

	# When already visible, only update the text.
	# Do not restart the fade animation.
	if interaction_prompt.visible:
		return

	if interaction_prompt_tween != null:
		interaction_prompt_tween.kill()

	interaction_prompt.modulate.a = 0.0
	interaction_prompt.show()

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
	resource_gain_popup.size = Vector2(280.0, 24.0)

	var start_position := Vector2(
		screen_position.x - 140.0,
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

func set_backpack_weight(
	current_weight: int,
	maximum_weight: int
) -> void:
	backpack_label.text = "Backpack %d/%d" % [
		current_weight,
		maximum_weight
	]

	if current_weight >= maximum_weight:
		backpack_label.modulate = Color("#e38b65")
	else:
		backpack_label.modulate = Color.WHITE


func show_delivery_summary(
	delivered_resources: Dictionary
) -> void:
	_set_delivery_line(
		wood_delivery_label,
		delivered_resources,
		ResourceTypes.Type.WOOD
	)

	_set_delivery_line(
		stone_delivery_label,
		delivered_resources,
		ResourceTypes.Type.STONE
	)

	_set_delivery_line(
		food_delivery_label,
		delivered_resources,
		ResourceTypes.Type.FOOD
	)

	if delivery_tween != null:
		delivery_tween.kill()

	delivery_popup.show()
	delivery_popup.modulate.a = 0.0
	delivery_popup.scale = Vector2(0.94, 0.94)
	delivery_popup.pivot_offset = (
		delivery_popup.size / 2.0
	)

	delivery_tween = create_tween()

	delivery_tween.tween_property(
		delivery_popup,
		"modulate:a",
		1.0,
		0.14
	)

	delivery_tween.parallel().tween_property(
		delivery_popup,
		"scale",
		Vector2.ONE,
		0.18
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	delivery_tween.tween_interval(1.5)

	delivery_tween.tween_property(
		delivery_popup,
		"modulate:a",
		0.0,
		0.25
	)

	delivery_tween.tween_callback(
		_finish_delivery_popup
	)


func _set_delivery_line(
	label: Label,
	delivered_resources: Dictionary,
	resource_type: int
) -> void:
	var amount := int(
		delivered_resources.get(
			resource_type,
			0
		)
	)

	label.visible = amount > 0

	if amount <= 0:
		return

	var resource_name := (
		ResourceTypes.get_display_name(
			resource_type
		)
	)

	label.text = "+%d %s" % [
		amount,
		resource_name
	]


func _finish_delivery_popup() -> void:
	delivery_popup.hide()
	delivery_popup.modulate.a = 1.0
	delivery_popup.scale = Vector2.ONE

func show_milestone(message: String) -> void:
	if milestone_tween != null:
		milestone_tween.kill()

	milestone_label.text = message

	milestone_popup.modulate.a = 0.0
	milestone_popup.scale = Vector2(0.92, 0.92)
	milestone_popup.show()

	milestone_tween = create_tween()

	milestone_tween.set_parallel(true)

	milestone_tween.tween_property(
		milestone_popup,
		"modulate:a",
		1.0,
		0.2
	)

	milestone_tween.tween_property(
		milestone_popup,
		"scale",
		Vector2.ONE,
		0.2
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

	milestone_tween.set_parallel(false)

	milestone_tween.tween_interval(3.5)

	milestone_tween.tween_property(
		milestone_popup,
		"modulate:a",
		0.0,
		0.4
	)

	milestone_tween.tween_callback(
		milestone_popup.hide
	)


func show_tutorial_hint(message: String) -> void:
	if tutorial_hint_tween != null:
		tutorial_hint_tween.kill()

	tutorial_label.text = message

	if tutorial_hint.visible:
		tutorial_hint.modulate.a = 1.0
		tutorial_hint.scale = Vector2.ONE
		return

	tutorial_hint.modulate.a = 0.0
	tutorial_hint.scale = Vector2(0.94, 0.94)
	tutorial_hint.show()

	tutorial_hint_tween = create_tween()
	tutorial_hint_tween.set_parallel(true)

	tutorial_hint_tween.tween_property(
		tutorial_hint,
		"modulate:a",
		1.0,
		0.18
	)

	tutorial_hint_tween.tween_property(
		tutorial_hint,
		"scale",
		Vector2.ONE,
		0.2
	).set_trans(
		Tween.TRANS_BACK
	).set_ease(
		Tween.EASE_OUT
	)

func hide_tutorial_hint() -> void:
	if not tutorial_hint.visible:
		return

	if tutorial_hint_tween != null:
		tutorial_hint_tween.kill()

	tutorial_hint_tween = create_tween()

	tutorial_hint_tween.tween_property(
		tutorial_hint,
		"modulate:a",
		0.0,
		0.15
	)

	tutorial_hint_tween.tween_callback(
		_finish_hiding_tutorial_hint
	)


func _finish_hiding_tutorial_hint() -> void:
	tutorial_hint.hide()
	tutorial_hint.modulate.a = 1.0
	tutorial_hint.scale = Vector2.ONE
