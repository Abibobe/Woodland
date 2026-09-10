class_name BackpackGrid
extends Control

signal resource_selected(resource_type: int)

@export_category("Resource Icons")
@export var food_icon: Texture2D
@export var wood_icon: Texture2D
@export var stone_icon: Texture2D


const GRID_COLUMNS := 6
const SLOT_SIZE := Vector2(56.0, 56.0)
const SLOT_GAP := 4.0

const EMPTY_COLOR := Color("#17231d")
const EMPTY_BORDER_COLOR := Color("#42554a")
const FOOD_COLOR := Color("#6f3546")
const WOOD_COLOR := Color("#70482b")
const STONE_COLOR := Color("#596065")
const ACTIVE_BORDER_COLOR := Color("#f2d479")


var background_slots: Array[PanelContainer] = []
var item_blocks: Array[PanelContainer] = []
var current_slot_count := 0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func refresh(
	contents: Dictionary,
	maximum_weight: int
) -> void:
	_ensure_slot_count(maximum_weight)
	_clear_item_blocks()

	var row_count := ceili(
		float(maximum_weight) / float(GRID_COLUMNS)
	)

	var used_columns: Array[int] = []

	for row_index in range(row_count):
		used_columns.append(0)

	var resource_order := [
		ResourceTypes.Type.STONE,
		ResourceTypes.Type.WOOD,
		ResourceTypes.Type.FOOD
	]

	for resource_type in resource_order:
		var amount := int(contents.get(resource_type, 0))
		var weight := _get_resource_weight(resource_type)

		for item_index in range(amount):
			var target_row := _find_best_row(
				used_columns,
				weight
			)

			if target_row < 0:
				push_warning(
					"Could not place backpack item in grid."
				)
				continue

			var target_column := used_columns[target_row]

			_create_item_block(
				resource_type,
				target_column,
				target_row,
				weight
			)

			used_columns[target_row] += weight


func _find_best_row(
	used_columns: Array[int],
	item_weight: int
) -> int:
	var selected_row := -1
	var smallest_remaining_space := GRID_COLUMNS + 1

	for row_index in range(used_columns.size()):
		var remaining_space := (
			GRID_COLUMNS - used_columns[row_index]
		)

		if remaining_space < item_weight:
			continue

		if remaining_space < smallest_remaining_space:
			smallest_remaining_space = remaining_space
			selected_row = row_index

	return selected_row


func _ensure_slot_count(required_slots: int) -> void:
	if current_slot_count == required_slots:
		return

	for child in get_children():
		child.queue_free()

	background_slots.clear()
	item_blocks.clear()
	current_slot_count = required_slots

	var row_count := ceili(
		float(required_slots) / float(GRID_COLUMNS)
	)

	custom_minimum_size = Vector2(
		GRID_COLUMNS * SLOT_SIZE.x
			+ (GRID_COLUMNS - 1) * SLOT_GAP,
		row_count * SLOT_SIZE.y
			+ (row_count - 1) * SLOT_GAP
	)

	for slot_index in range(required_slots):
		var panel := PanelContainer.new()
		var column := slot_index % GRID_COLUMNS
		var row := floori(
			float(slot_index) / float(GRID_COLUMNS)
		)

		panel.position = _get_cell_position(column, row)
		panel.size = SLOT_SIZE
		panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		panel.add_theme_stylebox_override(
			"panel",
			_create_slot_style(
				EMPTY_COLOR,
				EMPTY_BORDER_COLOR,
				1
			)
		)

		add_child(panel)
		background_slots.append(panel)

func _clear_item_blocks() -> void:
	for item_block in item_blocks:
		if not is_instance_valid(item_block):
			continue

		# Prevent another click while waiting for deletion.
		item_block.mouse_filter = (
			Control.MOUSE_FILTER_IGNORE
		)

		item_block.queue_free()

	item_blocks.clear()


func _create_item_block(
	resource_type: int,
	column: int,
	row: int,
	weight: int
) -> void:
	var panel := PanelContainer.new()
	var icon := TextureRect.new()

	panel.position = _get_cell_position(column, row)
	panel.size = Vector2(
		weight * SLOT_SIZE.x + (weight - 1) * SLOT_GAP,
		SLOT_SIZE.y
	)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.mouse_default_cursor_shape = (
		Control.CURSOR_POINTING_HAND
	)

	panel.tooltip_text = (
		"Deposit 1 %s — %d KG"
		% [
			ResourceTypes.get_display_name(
				resource_type
			),
			weight
		]
	)

	panel.gui_input.connect(
		_on_item_block_gui_input.bind(
			resource_type
		)
	)
	
	panel.mouse_entered.connect(
		_on_item_mouse_entered.bind(
			panel,
			resource_type
		)
	)

	panel.mouse_exited.connect(
		_on_item_mouse_exited.bind(
			panel,
			resource_type
		)
	)
	
	panel.z_index = 2
	panel.add_theme_stylebox_override(
		"panel",
		_create_slot_style(
			_get_resource_color(resource_type),
			ACTIVE_BORDER_COLOR,
			2
		)
	)

	icon.texture = _get_resource_icon(resource_type)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	icon.offset_left = 5.0
	icon.offset_top = 5.0
	icon.offset_right = -5.0
	icon.offset_bottom = -5.0
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	panel.add_child(icon)
	add_child(panel)
	item_blocks.append(panel)


func _get_cell_position(column: int, row: int) -> Vector2:
	return Vector2(
		column * (SLOT_SIZE.x + SLOT_GAP),
		row * (SLOT_SIZE.y + SLOT_GAP)
	)


func _create_slot_style(
	background_color: Color,
	border_color: Color,
	border_width: int
) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background_color
	style.border_color = border_color
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(2)
	return style


func _get_resource_color(resource_type: int) -> Color:
	match resource_type:
		ResourceTypes.Type.FOOD:
			return FOOD_COLOR
		ResourceTypes.Type.WOOD:
			return WOOD_COLOR
		ResourceTypes.Type.STONE:
			return STONE_COLOR
	return EMPTY_COLOR


func _get_resource_icon(resource_type: int) -> Texture2D:
	match resource_type:
		ResourceTypes.Type.FOOD:
			return food_icon
		ResourceTypes.Type.WOOD:
			return wood_icon
		ResourceTypes.Type.STONE:
			return stone_icon
	return null


func _get_resource_weight(resource_type: int) -> int:
	match resource_type:
		ResourceTypes.Type.FOOD:
			return 1
		ResourceTypes.Type.WOOD:
			return 2
		ResourceTypes.Type.STONE:
			return 3
	return 0

func _on_item_block_gui_input(
	event: InputEvent,
	resource_type: int
) -> void:
	if not event is InputEventMouseButton:
		return

	var mouse_event := (
		event as InputEventMouseButton
	)

	if mouse_event.button_index != MOUSE_BUTTON_LEFT:
		return

	if not mouse_event.pressed:
		return

	resource_selected.emit(resource_type)
	accept_event()


func _on_item_mouse_entered(
	panel: PanelContainer,
	resource_type: int
) -> void:
	if not is_instance_valid(panel):
		return

	panel.add_theme_stylebox_override(
		"panel",
		_create_slot_style(
			_get_resource_color(
				resource_type
			).lightened(0.10),
			Color("#fff0a3"),
			2
		)
	)


func _on_item_mouse_exited(
	panel: PanelContainer,
	resource_type: int
) -> void:
	if not is_instance_valid(panel):
		return

	panel.add_theme_stylebox_override(
		"panel",
		_create_slot_style(
			_get_resource_color(
				resource_type
			),
			ACTIVE_BORDER_COLOR,
			2
		)
	)
