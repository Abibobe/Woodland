The next step should be cleanup rather than another feature. We can safely remove:

- `DepositTimer` from `game.tscn`.
- `deposit_timer` and `deposit_camp` from `GameManager`.
- The obsolete automatic-deposit functions.
- The original compact `Panel` from `camp_menu.tscn`.
- Its old node references from `camp_menu.gd`.
- Any unused delivery-summary helper or HUD call.

That will leave one clear camp workflow and prevent the old system from causing unexpected deposits later.


Now we can remove the obsolete code without affecting manual transfers.

### 1. Remove `DepositTimer`

In `game.tscn`, delete:

```
DepositTimer
```

### 2. Clean `game_manager.gd`

Remove:

```
@onready var deposit_timer: Timer = $DepositTimer
```

Remove:

```
var deposit_camp: Camp
```

Remove these signal connections from `_ready()`:

```
player_interaction.interaction_target_entered.connect(
	_on_interaction_target_entered
)

player_interaction.interaction_target_exited.connect(
	_on_interaction_target_exited
)
```

Also remove this connection if it still exists:

```
deposit_timer.timeout.connect(
	_on_deposit_timer_timeout
)
```

Delete these three complete functions:

```
func _on_interaction_target_entered(...)
```

```
func _on_interaction_target_exited(...)
```

```
func _on_deposit_timer_timeout(...)
```

Keep `_format_delivery_summary()` because the new manual `Deposit All` function still uses it.

### 3. Remove the old camp panel

In `camp_menu.tscn`, delete the complete old branch:

```
CampMenu
└── Panel
    └── MarginContainer
        └── Content
```

Do not delete:

```
Background
CenterContainer
```

### 4. Remove the old references from `camp_menu.gd`

Delete:

```
@onready var panel: PanelContainer = $Panel
```

Delete the old references:

```
@onready var title_label: Label = (...)
@onready var cost_label: Label = (...)
@onready var message_label: Label = (...)
@onready var build_button: Button = (...)
@onready var close_button: Button = (...)
```

Keep the newer versions:

```
new_cost_label
new_message_label
new_build_button
new_close_button
```

Remove every remaining:

```
panel.hide()
```

There should no longer be any `$Panel` reference in the script.

### 5. Verify `_ready()`

The relevant part should now resemble:

```
func _ready() -> void:
	new_build_button.pressed.connect(
		_on_build_button_pressed
	)

	new_close_button.pressed.connect(
		_on_close_button_pressed
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

	get_viewport().size_changed.connect(
		_apply_layout
	)

	background.hide()
	center_container.hide()
	hide()

	call_deferred("_apply_layout")
```

### 6. Verify `_apply_layout()`

It should no longer size or position the old panel:

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

### Final test

- Approaching camp does not deposit anything.
- E opens the camp screen.
- Clicking an item deposits one unit.
- `Deposit All` transfers everything.
- `Take One` respects available weight.
- Construction spends only stored resources.
- Closing restores movement, hunger and time.
- Re-entering camp preserves storage.
- No missing-node or invalid-property errors appear.

The old automatic deposit workflow is now completely removed, leaving the new camp screen as the single source of truth.