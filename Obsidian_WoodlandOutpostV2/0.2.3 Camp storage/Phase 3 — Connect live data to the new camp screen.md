We’ll activate the new layout but keep automatic depositing for one final phase. This lets us verify the interface before changing resource movement.

### 1. Update `camp_menu.gd`

Add the new node references beneath the existing `@onready` variables:

```
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
```

For now, leave the old references in place. This avoids breaking anything while migrating.

### 2. Replace `_ready()`

```
func _ready() -> void:
	new_build_button.pressed.connect(
		_on_build_button_pressed
	)

	new_close_button.pressed.connect(
		_on_close_button_pressed
	)

	# The old compact panel is no longer displayed, but remains
	# available until the migration is complete.
	panel.hide()
	background.hide()
	center_container.hide()
	hide()
```

### 3. Replace `open_menu()`

```
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
```

### 4. Replace `close_menu()`

```
func close_menu() -> void:
	background.hide()
	center_container.hide()
	hide()
```

### 5. Replace `show_message()`

```
func show_message(text: String) -> void:
	new_message_label.text = text
```

### 6. Add the resource-display method

```
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
```

The `Deposit All` button is visible but intentionally does nothing yet.

### 7. Update `GameManager._refresh_camp_menu()`

After the existing `camp_menu.open_menu(...)` call, add:

```
camp_menu.refresh_resources(
	backpack.get_all_resources(),
	backpack.get_current_weight(),
	backpack.maximum_weight,
	inventory.get_all_resources()
)
```

The complete function becomes:

```
func _refresh_camp_menu() -> void:
	if active_camp == null:
		return

	var costs := active_camp.get_next_stage_cost()
	var is_complete := costs.is_empty()

	camp_menu.open_menu(
		active_camp.get_next_stage_name(),
		_format_cost(costs),
		_can_afford(costs),
		is_complete
	)

	camp_menu.refresh_resources(
		backpack.get_all_resources(),
		backpack.get_current_weight(),
		backpack.maximum_weight,
		inventory.get_all_resources()
	)
```

### Test

Approach the camp and press E. Verify:

- The dark full-screen background appears.
- The backpack is on the left.
- Camp storage is on the right.
- Stored quantities are correct.
- Construction cost and build availability are correct.
- Build still works.
- Close restores movement and time.
- The standalone TAB backpack still works.

The backpack will probably be empty because automatic depositing is still active. That is expected. Next we’ll activate `Deposit All` and remove the automatic deposit timer.

### Issue: 

![[Pasted image 20260910105550.png]]

## FiX:::

### Fix `camp_menu.gd`

In `_ready()`, add the layout connection:

```
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

	panel.hide()
	background.hide()
	center_container.hide()
	hide()

	call_deferred("_apply_layout")
```

Then add this new function:

```
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
```

### Check the scene properties

Select the root `CampMenu` and choose:

```
Layout → Anchors Preset → Full Rect
```

Then select `Background`:

```
Layout → Anchors Preset → Full Rect
Mouse Filter: Stop
```

Select `CenterContainer`:

```
Layout → Anchors Preset → Full Rect
Mouse Filter: Ignore
```

Select `CampWorkspace`:

```
Custom Minimum Size: 940 × 430
```

Also confirm:

```
CampMenu
├── Panel               Visible: Off
├── Background
└── CenterContainer
```

The old `Panel` should remain hidden. The `Background` and `CenterContainer` are shown by `open_menu()`.

After this correction, the dark background should cover the entire game and the `940 × 430` camp workspace should be centred, with the backpack on the left and camp storage on the right.