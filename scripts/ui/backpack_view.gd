class_name BackpackView
extends Control


@onready var capacity_label: Label = (
	$CenterContainer/BackpackPanel/MarginContainer/
	Content/Header/CapacityLabel
)

@onready var slot_grid: GridContainer = (
	$CenterContainer/BackpackPanel/MarginContainer/
	Content/SlotGrid
)

@onready var summary_label: Label = (
	$CenterContainer/BackpackPanel/MarginContainer/
	Content/SummaryLabel
)

@onready var hint_label: Label = (
	$CenterContainer/BackpackPanel/MarginContainer/
	Content/HintLabel
)


const EMPTY_COLOR := Color("#17231d")
const EMPTY_BORDER_COLOR := Color("#42554a")

const FOOD_COLOR := Color("#6f3546")
const WOOD_COLOR := Color("#70482b")
const STONE_COLOR := Color("#596065")

const ACTIVE_BORDER_COLOR := Color("#f2d479")
const TEXT_COLOR := Color("#f2ead0")


var slots: Array[PanelContainer] = []
var slot_labels: Array[Label] = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	hide()


func open_view(
	contents: Dictionary,
	current_weight: int,
	maximum_weight: int
) -> void:
	_refresh_slots(
		contents,
		current_weight,
		maximum_weight
	)

	show()


func close_view() -> void:
	hide()


func refresh(
	contents: Dictionary,
	current_weight: int,
	maximum_weight: int
) -> void:
	_refresh_slots(
		contents,
		current_weight,
		maximum_weight
	)


func _refresh_slots(
	contents: Dictionary,
	current_weight: int,
	maximum_weight: int
) -> void:
	_ensure_slot_count(maximum_weight)
	_clear_slots()

	var next_slot := 0

	# Heavy resources are packed first so their size is
	# immediately visible.
	var resource_order := [
		ResourceTypes.Type.STONE,
		ResourceTypes.Type.WOOD,
		ResourceTypes.Type.FOOD
	]

	for resource_type in resource_order:
		var amount := int(
			contents.get(resource_type, 0)
		)

		var weight := _get_resource_weight(
			resource_type
		)

		for item_index in range(amount):
			for weight_index in range(weight):
				if next_slot >= slots.size():
					break

				_fill_slot(
					next_slot,
					resource_type,
					weight_index == 0
				)

				next_slot += 1

	capacity_label.text = "%d / %d KG" % [
		current_weight,
		maximum_weight
	]

	var food_amount := int(
		contents.get(
			ResourceTypes.Type.FOOD,
			0
		)
	)

	var wood_amount := int(
		contents.get(
			ResourceTypes.Type.WOOD,
			0
		)
	)

	var stone_amount := int(
		contents.get(
			ResourceTypes.Type.STONE,
			0
		)
	)

	summary_label.text = (
		"Food %d  •  Wood %d  •  Stone %d"
		% [
			food_amount,
			wood_amount,
			stone_amount
		]
	)

	hint_label.text = (
		"TAB — Close"
		if food_amount <= 0
		else "TAB — Close    F — Eat Food"
	)


func _ensure_slot_count(
	required_slots: int
) -> void:
	if slots.size() == required_slots:
		return

	for child in slot_grid.get_children():
		child.queue_free()

	slots.clear()
	slot_labels.clear()

	for slot_index in range(required_slots):
		var panel := PanelContainer.new()
		var label := Label.new()

		panel.custom_minimum_size = Vector2(
			78.0,
			58.0
		)

		panel.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)

		label.horizontal_alignment = (
			HORIZONTAL_ALIGNMENT_CENTER
		)

		label.vertical_alignment = (
			VERTICAL_ALIGNMENT_CENTER
		)

		label.add_theme_font_size_override(
			"font_size",
			10
		)

		label.add_theme_color_override(
			"font_color",
			TEXT_COLOR
		)

		label.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)

		panel.add_child(label)
		slot_grid.add_child(panel)

		slots.append(panel)
		slot_labels.append(label)


func _clear_slots() -> void:
	for slot_index in range(slots.size()):
		var panel := slots[slot_index]
		var label := slot_labels[slot_index]

		label.text = ""

		panel.add_theme_stylebox_override(
			"panel",
			_create_slot_style(
				EMPTY_COLOR,
				EMPTY_BORDER_COLOR
			)
		)


func _fill_slot(
	slot_index: int,
	resource_type: int,
	is_first_weight_slot: bool
) -> void:
	var panel := slots[slot_index]
	var label := slot_labels[slot_index]

	var slot_color := EMPTY_COLOR
	var resource_text := ""

	match resource_type:
		ResourceTypes.Type.FOOD:
			slot_color = FOOD_COLOR
			resource_text = "FOOD"

		ResourceTypes.Type.WOOD:
			slot_color = WOOD_COLOR
			resource_text = "WOOD"

		ResourceTypes.Type.STONE:
			slot_color = STONE_COLOR
			resource_text = "STONE"

	label.text = (
		resource_text
		if is_first_weight_slot
		else "·"
	)

	panel.add_theme_stylebox_override(
		"panel",
		_create_slot_style(
			slot_color,
			ACTIVE_BORDER_COLOR
		)
	)


func _create_slot_style(
	background_color: Color,
	border_color: Color
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()

	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)

	return style


func _get_resource_weight(
	resource_type: int
) -> int:
	match resource_type:
		ResourceTypes.Type.FOOD:
			return 1

		ResourceTypes.Type.WOOD:
			return 2

		ResourceTypes.Type.STONE:
			return 3

	return 0
