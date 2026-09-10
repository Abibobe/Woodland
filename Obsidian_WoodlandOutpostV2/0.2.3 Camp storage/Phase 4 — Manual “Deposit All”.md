Now resources will remain in the backpack until the player opens the camp and deliberately deposits them.

### 1. Add the camp signal

Near the top of `camp_menu.gd`, add:

```
signal deposit_all_requested
```

Your signals should be:

```
signal build_requested
signal close_requested
signal deposit_all_requested
```

In `_ready()`, connect the button:

```
deposit_all_button.pressed.connect(
	_on_deposit_all_button_pressed
)
```

Then add:

```
func _on_deposit_all_button_pressed() -> void:
	deposit_all_requested.emit()
```

### 2. Connect it in `GameManager`

In `GameManager._ready()`, add:

```
camp_menu.deposit_all_requested.connect(
	_on_camp_deposit_all_requested
)
```

### 3. Add the deposit function

Add this function near the other camp functions:

```
func _on_camp_deposit_all_requested() -> void:
	if active_camp == null:
		return

	if backpack.is_empty():
		camp_menu.show_message(
			"Your backpack is empty"
		)

		_play_ui_denied()
		return

	_play_ui_click()

	var delivered_resources := backpack.take_all()

	for resource_type in delivered_resources:
		var delivered_amount := int(
			delivered_resources[resource_type]
		)

		if delivered_amount <= 0:
			continue

		inventory.add_resource(
			int(resource_type),
			delivered_amount
		)

	camp_menu.show_message(
		_format_delivery_summary(
			delivered_resources
		)
	)

	if (
		tutorial_step == TutorialStep.BACKPACK
		or tutorial_step == TutorialStep.RETURN_TO_CAMP
	):
		_set_tutorial_step(
			TutorialStep.CONSTRUCTION
		)

	_check_next_camp_stage_affordability()
	_refresh_camp_menu()
```

### 4. Stop automatic depositing

In `_ready()`, remove this connection:

```
deposit_timer.timeout.connect(
	_on_deposit_timer_timeout
)
```

Replace `_on_interaction_target_entered()` with:

```
func _on_interaction_target_entered(
	target: InteractionTarget
) -> void:
	if not target is Camp:
		return

	if not deposit_timer.is_stopped():
		deposit_timer.stop()

	deposit_camp = null
```

Replace `_on_interaction_target_exited()` with:

```
func _on_interaction_target_exited(
	target: InteractionTarget
) -> void:
	if not target is Camp:
		return

	if not deposit_timer.is_stopped():
		deposit_timer.stop()

	deposit_camp = null
```

You can leave `_on_deposit_timer_timeout()` in the script temporarily. Nothing calls it now, so it cannot deposit anything. We’ll remove the obsolete timer and functions after the complete transfer system works.

### 5. Improve the button label

In `camp_menu.gd`, inside `refresh_resources()`, after disabling the button, add:

```
if current_weight <= 0:
	deposit_all_button.text = "BACKPACK EMPTY"
else:
	deposit_all_button.text = (
		"DEPOSIT ALL — %d KG →"
		% current_weight
	)
```

### Test

- Approach camp with resources: nothing should deposit automatically.
- Press E: the left grid should show everything still carried.
- Select `Deposit All`.
- The backpack grid should immediately empty.
- Camp quantities should increase.
- Construction affordability should update.
- The button should change to `BACKPACK EMPTY`.
- Close the menu: movement, time and hunger should resume.
- Gather something else and return: previously stored resources must remain.

Once this works, the automatic transaction has officially become a deliberate camp decision. Next we can make each resource block clickable for individual transfers in both directions.

![[Pasted image 20260910112929.png]]![[Pasted image 20260910113206.png]]

### ISSUE: I have some question about the graphic result. Seems like that we cannot see the resource icon in the new menu

Yes—the screenshot reveals the exact cause. The coloured item blocks appear correctly, so `BackpackGrid` is working, but their `TextureRect` objects have `null` textures.

The new camp `BackpackGrid` is a separate instance, so it does not inherit the icons assigned to the normal TAB backpack.

Select:

```
CampMenu
└── CenterContainer
    └── CampWorkspace
        └── MarginContainer
            └── MainRow
                └── BackpackSide
                    └── BackpackGrid
```

In the Inspector, assign:

```
Resource Icons
├── Food Icon  → backpack_food.png
├── Wood Icon  → backpack_wood.png
└── Stone Icon → backpack_stone.png
```

Make sure you assign them to the `BackpackGrid` inside `CampMenu`, not the standalone one inside `BackpackView`.

Your screenshot confirms the rest:

- The two brown two-cell blocks are the wood items.
- The purple one-cell block is food.
- The packing and weight calculations are correct.
- Only the artwork is missing.

I also notice the backpack capacity and camp headers are slightly colliding near the centre. After restoring the icons, increase `CampWorkspace` to approximately:

```
Custom Minimum Size: 1040 × 430
```

and set:

```
BackpackSide Minimum X: 400
CampSide Minimum X: 440
MainRow Separation: 30
```

That should give both headers comfortable space.

The camp storage currently uses text-only rows intentionally. Once the transfer logic is complete, we can add the same berry, log, and stone icons beside those stored quantities without making the interface too busy.

![[Pasted image 20260910113538.png]]