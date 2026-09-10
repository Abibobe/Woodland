class_name CampMenu
extends Control


signal build_requested
signal close_requested
signal deposit_all_requested
signal deposit_resource_requested(
	resource_type: int
)

signal withdraw_resource_requested(
	resource_type: int
)

@onready var background: ColorRect = $Background

@onready var center_container: CenterContainer = (
	$CenterContainer
)

@onready var backpack_grid: BackpackGrid = (
	$CenterContainer/CampWorkspace/MarginContainer/
	MainRow/BackpackSide/BackpackGrid
)

@onready var capacity_label: Label = (
	$CenterContainer/CampWorkspace/MarginContainer/
	MainRow/BackpackSide/BackpackHeader/CapacityLabel
)

@onready var backpack_summary: Label = (
	$CenterContainer/CampWorkspace/MarginContainer/
	MainRow/BackpackSide/BackpackSummary
)

@onready var deposit_all_button: Button = (
	$CenterContainer/CampWorkspace/MarginContainer/
	MainRow/BackpackSide/DepositAllButton
)

@onready var stage_label: Label = (
	$CenterContainer/CampWorkspace/MarginContainer/
	MainRow/CampSide/CampHeader/StageLabel
)

@onready var next_build_title: Label = (
	$CenterContainer/CampWorkspace/MarginContainer/
	MainRow/CampSide/NextBuildTitle
)

@onready var new_cost_label: Label = (
	$CenterContainer/CampWorkspace/MarginContainer/
	MainRow/CampSide/CostLabel
)

@onready var new_message_label: Label = (
	$CenterContainer/CampWorkspace/MarginContainer/
	MainRow/CampSide/MessageLabel
)

@onready var food_amount: Label = (
	$CenterContainer/CampWorkspace/MarginContainer/
	MainRow/CampSide/StorageRows/FoodRow/FoodAmount
)

@onready var wood_amount: Label = (
	$CenterContainer/CampWorkspace/MarginContainer/
	MainRow/CampSide/StorageRows/WoodRow/WoodAmount
)

@onready var stone_amount: Label = (
	$CenterContainer/CampWorkspace/MarginContainer/
	MainRow/CampSide/StorageRows/StoneRow/StoneAmount
)

@onready var new_build_button: Button = (
	$CenterContainer/CampWorkspace/MarginContainer/
	MainRow/CampSide/Buttons/BuildButton
)

@onready var new_close_button: Button = (
	$CenterContainer/CampWorkspace/MarginContainer/
	MainRow/CampSide/Buttons/CloseButton
)

@onready var panel: PanelContainer = $Panel

@onready var title_label: Label = (
	$Panel/MarginContainer/Content/TitleLabel
)

@onready var cost_label: Label = (
	$Panel/MarginContainer/Content/CostRow/CostLabel
)

@onready var message_label: Label = (
	$Panel/MarginContainer/Content/MessageLabel
)

@onready var build_button: Button = (
	$Panel/MarginContainer/Content/Buttons/BuildButton
)

@onready var close_button: Button = (
	$Panel/MarginContainer/Content/Buttons/CloseButton
)

@onready var take_food_button: Button = (
	$CenterContainer/CampWorkspace/MarginContainer/MainRow/CampSide/StorageRows/FoodRow/TakeFoodButton
)

@onready var take_wood_button: Button = (
	$CenterContainer/CampWorkspace/MarginContainer/MainRow/CampSide/StorageRows/WoodRow/TakeWoodButton
)

@onready var take_stone_button: Button = (
	$CenterContainer/CampWorkspace/MarginContainer/MainRow/CampSide/StorageRows/StoneRow/TakeStoneButton
)

func _ready() -> void:
	new_build_button.pressed.connect(
		_on_build_button_pressed
	)

	new_close_button.pressed.connect(
		_on_close_button_pressed
	)

	get_viewport().size_changed.connect(
		_apply_layout
	)

	deposit_all_button.pressed.connect(
		_on_deposit_all_button_pressed
	)
	
	backpack_grid.resource_selected.connect(
		_on_backpack_resource_selected
	)

	take_food_button.pressed.connect(
		_on_take_food_pressed
	)

	take_wood_button.pressed.connect(
		_on_take_wood_pressed
	)

	take_stone_button.pressed.connect(
		_on_take_stone_pressed
	)
	
	panel.hide()
	background.hide()
	center_container.hide()
	hide()

	call_deferred("_apply_layout")

func _on_deposit_all_button_pressed() -> void:
	deposit_all_requested.emit()
	
func open_menu(
	next_stage_name: String,
	cost_text: String,
	can_build: bool,
	is_complete: bool
) -> void:
	panel.hide()
	new_message_label.text = ""

	if is_complete:
		stage_label.text = "CABIN"
		next_build_title.text = "CABIN COMPLETE"
		new_cost_label.text = "Ready for winter"
		new_build_button.hide()
	else:
		stage_label.text = "CONSTRUCTION"

		next_build_title.text = (
			"NEXT BUILD — %s"
			% next_stage_name.to_upper()
		)

		new_cost_label.text = (
			"Required: %s" % cost_text
		)

		new_build_button.text = (
			"BUILD %s"
			% next_stage_name.to_upper()
		)

		new_build_button.show()
		new_build_button.disabled = not can_build

		if can_build:
			new_cost_label.modulate = Color(
				"#f2e7c9"
			)
		else:
			new_cost_label.modulate = Color(
				"#e06c68"
			)

	show()
	background.show()
	center_container.show()


func close_menu() -> void:
	background.hide()
	center_container.hide()
	hide()


func show_message(text: String) -> void:
	new_message_label.text = text


func _on_build_button_pressed() -> void:
	build_requested.emit()


func _on_close_button_pressed() -> void:
	close_requested.emit()


func refresh_resources(
	backpack_contents: Dictionary,
	current_weight: int,
	maximum_weight: int,
	camp_contents: Dictionary
) -> void:
	backpack_grid.refresh(
		backpack_contents,
		maximum_weight
	)

	capacity_label.text = "%d / %d KG" % [
		current_weight,
		maximum_weight
	]

	var carried_food := int(
		backpack_contents.get(
			ResourceTypes.Type.FOOD,
			0
		)
	)

	var carried_wood := int(
		backpack_contents.get(
			ResourceTypes.Type.WOOD,
			0
		)
	)

	var carried_stone := int(
		backpack_contents.get(
			ResourceTypes.Type.STONE,
			0
		)
	)

	backpack_summary.text = (
		"Food %d  •  Wood %d  •  Stone %d"
		% [
			carried_food,
			carried_wood,
			carried_stone
		]
	)

	food_amount.text = "×%d" % int(
		camp_contents.get(
			ResourceTypes.Type.FOOD,
			0
		)
	)

	wood_amount.text = "×%d" % int(
		camp_contents.get(
			ResourceTypes.Type.WOOD,
			0
		)
	)

	stone_amount.text = "×%d" % int(
		camp_contents.get(
			ResourceTypes.Type.STONE,
			0
		)
	)

	deposit_all_button.disabled = (
		current_weight <= 0
	)
	
	if current_weight <= 0:
		deposit_all_button.text = "BACKPACK EMPTY"
	else:
		deposit_all_button.text = (
			"DEPOSIT ALL — %d KG →"
			% current_weight
		)
	
	take_food_button.disabled = (
		int(
			camp_contents.get(
				ResourceTypes.Type.FOOD,
				0
			)
		) <= 0
	)

	take_wood_button.disabled = (
		int(
			camp_contents.get(
				ResourceTypes.Type.WOOD,
				0
			)
		) <= 0
	)

	take_stone_button.disabled = (
		int(
			camp_contents.get(
				ResourceTypes.Type.STONE,
				0
			)
		) <= 0
	)

func _apply_layout() -> void:
	set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	background.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	center_container.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

func _on_backpack_resource_selected(
	resource_type: int
) -> void:
	deposit_resource_requested.emit(
		resource_type
	)


func _on_take_food_pressed() -> void:
	withdraw_resource_requested.emit(
		ResourceTypes.Type.FOOD
	)


func _on_take_wood_pressed() -> void:
	withdraw_resource_requested.emit(
		ResourceTypes.Type.WOOD
	)


func _on_take_stone_pressed() -> void:
	withdraw_resource_requested.emit(
		ResourceTypes.Type.STONE
	)

func show_transfer_feedback(
	resource_type: int,
	deposited: bool
) -> void:
	var target: Control

	if deposited:
		match resource_type:
			ResourceTypes.Type.FOOD:
				target = food_amount

			ResourceTypes.Type.WOOD:
				target = wood_amount

			ResourceTypes.Type.STONE:
				target = stone_amount
	else:
		target = backpack_grid

	if target == null:
		return

	var tween := create_tween()

	target.modulate = Color("#fff0a3")

	tween.tween_property(
		target,
		"modulate",
		Color.WHITE,
		0.25
	)
