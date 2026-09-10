
1. Food eatened from the camp storage open menu is not deleted correctly
The food is removed correctly from `PlayerBackpack`, but the resource-change signal currently refreshes only the standalone TAB backpack. The `BackpackGrid` inside `CampMenu` never receives the new contents.

### Add a camp-inventory refresh helper

In `game_manager.gd`, add:

```
func _refresh_camp_resource_display() -> void:
	if active_camp == null:
		return

	if not camp_menu.visible:
		return

	camp_menu.refresh_resources(
		backpack.get_all_resources(),
		backpack.get_current_weight(),
		backpack.maximum_weight,
		inventory.get_all_resources()
	)
```

### Update the backpack signal handler

Replace:

```
func _on_backpack_resource_changed(
	_resource_type: int,
	_new_amount: int
) -> void:
	_refresh_backpack_view()
```

with:

```
func _on_backpack_resource_changed(
	_resource_type: int,
	_new_amount: int
) -> void:
	_refresh_backpack_view()
	_refresh_camp_resource_display()
```

### Update the camp-storage signal handler

Also replace:

```
func _on_inventory_resource_changed(
	resource_type: int,
	new_amount: int
) -> void:
	hud.set_resource_amount(
		resource_type,
		new_amount
	)
```

with:

```
func _on_inventory_resource_changed(
	resource_type: int,
	new_amount: int
) -> void:
	hud.set_resource_amount(
		resource_type,
		new_amount
	)

	_refresh_camp_resource_display()
```

This second change ensures the camp quantities also update immediately when food is eaten from storage.

Now, while the camp menu is open:

- Eating carried food removes its icon immediately.
- Eating stored food reduces the camp quantity immediately.
- Capacity and backpack summary update.
- Construction messages are not reset because we refresh only the inventories—not the entire camp menu.


2. Menu is behind the backpack
   
This happens because both `GameManager` and `PauseMenu` receive Escape. The backpack closes correctly, but the pause menu also opens during the same input event—behind the backpack’s closing animation.

The pause menu should ignore Escape whenever another full-screen interface is open.

### Update `pause_menu.gd`

Add:

```
@export var backpack_view: Control
@export var camp_menu: Control
```

At the very beginning of its `_unhandled_input()` function, add:

```
func _unhandled_input(event: InputEvent) -> void:
	if (
		is_instance_valid(backpack_view)
		and backpack_view.visible
	):
		return

	if (
		is_instance_valid(camp_menu)
		and camp_menu.visible
	):
		return

	# Keep the existing pause-menu input code below.
```

Do not replace the rest of the function—only add these checks at its beginning.

### Assign the references

Select `PauseMenu` in `game.tscn` and assign:

```
Backpack View → Interface/BackpackView
Camp Menu     → Interface/CampMenu
```

Now Escape behaves contextually:

- Backpack open → closes only the backpack.
- Camp menu open → closes only the camp menu.
- Normal gameplay → opens the pause menu.
- Pause menu open → closes the pause menu.

The visibility check remains true throughout the backpack’s closing animation, so the same Escape press cannot leak through and open another menu behind it.

I found the real cause: `PauseMenu` checks Escape inside `_process()`:

```
Input.is_action_just_pressed("ui_cancel")
```

This polling ignores `set_input_as_handled()`. Therefore, even after `GameManager` consumes Escape, `PauseMenu` still sees the key during the next process frame.

### 1. Fix z-index for the pause menu

set z index of PauseMenu in Game.tscn to 1000

### 2. Replace `_unhandled_input()`

Your current `_unhandled_input()` only checks the other interfaces and then ends. Replace the entire function with:

```
func _unhandled_input(
	event: InputEvent
) -> void:
	if event.is_echo():
		return

	if not event.is_action_pressed(
		"ui_cancel"
	):
		return

	# Let GameManager handle Escape while the backpack
	# or camp interface is open.
	if (
		is_instance_valid(backpack_view)
		and backpack_view.visible
	):
		return

	if (
		is_instance_valid(camp_menu)
		and camp_menu.visible
	):
		return

	_handle_pause_input()

	get_viewport().set_input_as_handled()
```

Keep `_handle_pause_input()` unchanged.

### Why this fixes it

The pause menu now reacts to the actual input event instead of polling the global keyboard state:

- `PauseMenu` sees that the backpack is visible and ignores Escape.
- The unhandled event continues to `GameManager`.
- `GameManager` closes the backpack and consumes the event.
- The pause menu never opens.

When no backpack or camp screen is visible, `PauseMenu` handles Escape normally and consumes it itself.