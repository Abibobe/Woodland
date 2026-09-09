class_name BackpackView
extends Control


signal view_closed


@onready var capacity_label: Label = (
	$CenterContainer/BackpackPanel/MarginContainer/
	Content/Header/CapacityLabel
)

@onready var backpack_grid: BackpackGrid = (
	$CenterContainer/BackpackPanel/MarginContainer/
	Content/BackpackGrid
)

@onready var summary_label: Label = (
	$CenterContainer/BackpackPanel/MarginContainer/
	Content/SummaryLabel
)

@onready var hint_label: Label = (
	$CenterContainer/BackpackPanel/MarginContainer/
	Content/HintLabel
)

@onready var background: ColorRect = $Background

@onready var backpack_panel: PanelContainer = (
	$CenterContainer/BackpackPanel
)


var view_tween: Tween
var is_closing := false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	hide()


func open_view(
	contents: Dictionary,
	current_weight: int,
	maximum_weight: int
) -> void:
	if view_tween != null:
		view_tween.kill()

	is_closing = false
	refresh(contents, current_weight, maximum_weight)

	background.modulate.a = 0.0
	backpack_panel.modulate.a = 0.0
	backpack_panel.scale = Vector2(0.92, 0.92)
	show()

	backpack_panel.pivot_offset = backpack_panel.size / 2.0

	view_tween = create_tween()
	view_tween.set_parallel(true)
	view_tween.tween_property(
		background,
		"modulate:a",
		1.0,
		0.16
	)
	view_tween.tween_property(
		backpack_panel,
		"modulate:a",
		1.0,
		0.12
	)
	view_tween.tween_property(
		backpack_panel,
		"scale",
		Vector2.ONE,
		0.20
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func close_view() -> void:
	if not visible or is_closing:
		return

	is_closing = true

	if view_tween != null:
		view_tween.kill()

	view_tween = create_tween()
	view_tween.set_parallel(true)
	view_tween.tween_property(
		background,
		"modulate:a",
		0.0,
		0.12
	)
	view_tween.tween_property(
		backpack_panel,
		"modulate:a",
		0.0,
		0.10
	)
	view_tween.tween_property(
		backpack_panel,
		"scale",
		Vector2(0.96, 0.96),
		0.12
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	view_tween.set_parallel(false)
	view_tween.tween_callback(_finish_closing)


func _finish_closing() -> void:
	hide()
	background.modulate.a = 1.0
	backpack_panel.modulate.a = 1.0
	backpack_panel.scale = Vector2.ONE
	is_closing = false
	view_closed.emit()


func refresh(
	contents: Dictionary,
	current_weight: int,
	maximum_weight: int
) -> void:
	backpack_grid.refresh(contents, maximum_weight)
	_update_text(contents, current_weight, maximum_weight)


func _update_text(
	contents: Dictionary,
	current_weight: int,
	maximum_weight: int
) -> void:
	capacity_label.text = "%d / %d KG" % [
		current_weight,
		maximum_weight
	]

	var food_amount := int(
		contents.get(ResourceTypes.Type.FOOD, 0)
	)
	var wood_amount := int(
		contents.get(ResourceTypes.Type.WOOD, 0)
	)
	var stone_amount := int(
		contents.get(ResourceTypes.Type.STONE, 0)
	)

	summary_label.text = (
		"Food %d  •  Wood %d  •  Stone %d"
		% [food_amount, wood_amount, stone_amount]
	)

	hint_label.text = (
		"TAB — Close"
		if food_amount <= 0
		else "TAB — Close    F — Eat Food"
	)
