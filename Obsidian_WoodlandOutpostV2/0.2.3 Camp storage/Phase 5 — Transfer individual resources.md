Next we’ll add individual transfers:

- Click a backpack resource block to deposit one item.
- Click a stored resource row to retrieve one item.
- Retrieval will check whether the item fits in the remaining backpack capacity.
- The build information will refresh after every transfer.
- A small message will explain rejected transfers, such as `Not enough backpack space`.

This will turn the camp screen from a resource display into the planning interface we originally imagined.

We’ll make backpack items clickable and add one retrieval button to each camp-storage row.

### 1. Make backpack blocks clickable

In `backpack_grid.gd`, add beneath `extends Control`:

```
signal resource_selected(resource_type: int)
```

Inside `_create_item_block()`, replace:

```
panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
```

with:

```
panel.mouse_filter = Control.MOUSE_FILTER_STOP
panel.mouse_default_cursor_shape = (
	Control.CURSOR_POINTING_HAND
)

panel.tooltip_text = (
	"Deposit 1 %s"
	% ResourceTypes.get_display_name(
		resource_type
	)
)

panel.gui_input.connect(
	_on_item_block_gui_input.bind(
		resource_type
	)
)
```

Add:

```
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
```

Clicking an item in the normal TAB backpack will do nothing because that screen does not connect the signal.

### 2. Add retrieval buttons

In `camp_menu.tscn`, add a button to every storage row:

```
FoodRow
├── FoodLabel
├── FoodSpacer
├── FoodAmount
└── TakeFoodButton

WoodRow
├── WoodLabel
├── WoodSpacer
├── WoodAmount
└── TakeWoodButton

StoneRow
├── StoneLabel
├── StoneSpacer
├── StoneAmount
└── TakeStoneButton
```

Set their text to:

```
← TAKE
```

Give each button a minimum width of approximately `70`.

### 3. Add camp-menu signals

In `camp_menu.gd`, add:

```
signal deposit_resource_requested(
	resource_type: int
)

signal withdraw_resource_requested(
	resource_type: int
)
```

Add the references:

```
@onready var take_food_button: Button = (
	$CenterContainer/CampWorkspace/MarginContainer/
	MainRow/CampSide/StorageRows/FoodRow/
	TakeFoodButton
)

@onready var take_wood_button: Button = (
	$CenterContainer/CampWorkspace/MarginContainer/
	MainRow/CampSide/StorageRows/WoodRow/
	TakeWoodButton
)

@onready var take_stone_button: Button = (
	$CenterContainer/CampWorkspace/MarginContainer/
	MainRow/CampSide/StorageRows/StoneRow/
	TakeStoneButton
)
```

In `_ready()`, add:

```
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
```

Add the handlers:

```
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
```

### 4. Disable unavailable retrieval buttons

At the end of `refresh_resources()`, add:

```
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
```


### 5. Connect the requests in `GameManager`

In `_ready()`, add:

```
camp_menu.deposit_resource_requested.connect(
	_on_camp_deposit_resource_requested
)

camp_menu.withdraw_resource_requested.connect(
	_on_camp_withdraw_resource_requested
)
```

Add:

```
func _on_camp_deposit_resource_requested(
	resource_type: int
) -> void:
	if active_camp == null:
		return

	if not backpack.remove_resource(
		resource_type,
		1
	):
		_play_ui_denied()
		return

	inventory.add_resource(
		resource_type,
		1
	)

	_play_ui_click()

	camp_menu.show_message(
		"Deposited 1 %s"
		% ResourceTypes.get_display_name(
			resource_type
		)
	)

	_check_next_camp_stage_affordability()
	_refresh_camp_menu()


func _on_camp_withdraw_resource_requested(
	resource_type: int
) -> void:
	if active_camp == null:
		return

	if not inventory.has_resources(
		resource_type,
		1
	):
		camp_menu.show_message(
			"No resources available"
		)

		_play_ui_denied()
		return

	if not backpack.can_add(
		resource_type,
		1
	):
		camp_menu.show_message(
			"Not enough backpack space"
		)

		_play_ui_denied()
		return

	if not inventory.remove_resource(
		resource_type,
		1
	):
		return

	if not backpack.add_resource(
		resource_type,
		1
	):
		# Defensive rollback if backpack capacity changed.
		inventory.add_resource(
			resource_type,
			1
		)
		return

	_play_ui_click()

	camp_menu.show_message(
		"Took 1 %s"
		% ResourceTypes.get_display_name(
			resource_type
		)
	)

	_check_next_camp_stage_affordability()
	_refresh_camp_menu()
```

### Test

- Click a log in the left grid: one wood moves into storage.
- Click a berry block: one food moves.
- Use `← TAKE`: one corresponding item returns.
- Wood retrieval requires 2 free kilograms.
- Stone retrieval requires 3.
- A full backpack shows `Not enough backpack space`.
- Empty storage disables its retrieval button.
- Build affordability updates after every transfer.
- `Deposit All` continues working.

Now the camp is a genuine transfer interface rather than an automatic unloading point.

### Issue: error when click on resources

The click signal immediately refreshes the grid while Godot is still processing that item’s `gui_input`. `_clear_item_blocks()` tries to destroy the exact panel currently handling the click, but Godot temporarily locks signal-emitting objects.

Use `queue_free()` so removal happens safely at the end of the frame.

In `backpack_grid.gd`, replace `_clear_item_blocks()` with:

```
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
```

For consistency, also update `_ensure_slot_count()`. Replace:

```
for child in get_children():
	child.free()
```

with:

```
for child in get_children():
	child.queue_free()
```

Why this works:

- `free()` destroys the object immediately, which is unsafe during its input callback.
- `queue_free()` schedules destruction after the current input event finishes.
- The old block stops receiving mouse input immediately.
- The refreshed resource blocks can be created safely during the same frame.

After this change, clicking a resource should transfer it and refresh both sides without the locked-object error.