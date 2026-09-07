I found the complete flow. Hunger can safely use `DayCycle.running`, which means it will stop during the camp menu; normal scene pausing already stops it during the main and pause menus.

Let’s implement the first playable version.

## Phase 1 — Add the hunger bar

In the scene tree, add these nodes under:

```
Interface
└── HUD
    └── TopBar
        └── MarginContainer
            └── ResourceRow
                ├── ...
                ├── HungerLabel
                ├── HungerBar
                └── BackpackLabel
```

Configure `HungerLabel`:

```
Text: Hunger
Font Size: 11
```

Configure `HungerBar`:

```
Custom Minimum Size: 110 × 14
Min Value: 0
Max Value: 100
Value: 100
Step: 1
Show Percentage: On
Mouse Filter: Ignore
```

Place them immediately before `BackpackLabel`.

## Phase 2 — Update `hud.gd`

Add this reference near the other `@onready` variables:

```
@onready var hunger_bar: ProgressBar = (
	$TopBar/MarginContainer/ResourceRow/HungerBar
)
```

Add this state variable:

```
var hunger_state := ""
```

In `_ready()`, add:

```
hunger_bar.min_value = 0.0
hunger_bar.max_value = 100.0
hunger_bar.value = 100.0
hunger_bar.show_percentage = true
```

Now add:

```
func set_hunger(
	current_hunger: float,
	maximum_hunger: float
) -> void:
	hunger_bar.max_value = maximum_hunger
	hunger_bar.value = current_hunger

	var ratio := current_hunger / maximum_hunger
	var new_state := "well_fed"

	if ratio <= 0.30:
		new_state = "starving"
	elif ratio <= 0.60:
		new_state = "hungry"

	if new_state == hunger_state:
		return

	hunger_state = new_state

	match hunger_state:
		"starving":
			hunger_bar.modulate = Color("#e36b5d")

		"hungry":
			hunger_bar.modulate = Color("#f2d479")

		_:
			hunger_bar.modulate = Color("#8fc96b")
```

This avoids rebuilding style resources every frame.

## Phase 3 — Add the input action

Open:

```
Project → Project Settings → Input Map
```

Add:

```
eat_food
```

Assign the `F` key.

## Phase 4 — Add hunger configuration

In `game_manager.gd`, below your tutorial exports, add:

```
@export_category("Hunger")

@export_range(1.0, 200.0, 1.0)
var maximum_hunger := 100.0

@export_range(1.0, 200.0, 1.0)
var starting_hunger := 100.0

@export_range(0.1, 5.0, 0.1)
var hunger_decrease_per_second := 1.0

@export_range(1.0, 100.0, 1.0)
var food_hunger_restoration := 80.0

@export_range(0.0, 100.0, 1.0)
var maximum_hunger_for_eating := 85.0
```

Near your other state variables, add:

```
var current_hunger := 100.0
var low_hunger_warning_shown := false
var critical_hunger_warning_shown := false
```

## Phase 5 — Initialise hunger

At the beginning of `_ready()`, immediately after:

```
_configure_world_layout()
```

add:

```
current_hunger = clampf(
	starting_hunger,
	0.0,
	maximum_hunger
)
```

At the end of `_update_entire_hud()`, add:

```
hud.set_hunger(
	current_hunger,
	maximum_hunger
)
```

## Phase 6 — Replace `_process()`

Your existing `_process()` only updates the movement tutorial. Replace it completely with:

```
func _process(delta: float) -> void:
	_update_hunger(delta)
	_update_movement_tutorial()
```

Then add:

```
func _update_hunger(delta: float) -> void:
	if game_finished:
		return

	if not day_cycle.running:
		return

	current_hunger = maxf(
		current_hunger
			- hunger_decrease_per_second * delta,
		0.0
	)

	hud.set_hunger(
		current_hunger,
		maximum_hunger
	)

	_check_hunger_warnings()

	if current_hunger <= 0.0:
		_finish_game(
			"Defeat",
			"You collapsed from hunger before the cabin was complete."
		)
```

Move the old tutorial logic into this new function:

```
func _update_movement_tutorial() -> void:
	if tutorial_step != TutorialStep.MOVEMENT:
		return

	var distance_moved := (
		player.global_position.distance_to(
			tutorial_start_position
		)
	)

	if distance_moved < tutorial_movement_distance:
		return

	_set_tutorial_step(
		TutorialStep.GATHERING
	)
```

## Phase 7 — Add warnings

Add:

```
func _check_hunger_warnings() -> void:
	var hunger_ratio := (
		current_hunger / maximum_hunger
	)

	if (
		hunger_ratio <= 0.30
		and not critical_hunger_warning_shown
	):
		critical_hunger_warning_shown = true

		hud.show_milestone(
			"STARVING!\nEAT FOOD SOON"
		)

		return

	if (
		hunger_ratio <= 0.60
		and not low_hunger_warning_shown
	):
		low_hunger_warning_shown = true

		hud.show_milestone(
			"YOU ARE GETTING HUNGRY\nPRESS F TO EAT"
		)
```

We will reset these warnings after eating.

## Phase 8 — Eat carried food

Add this input function:

```
func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("eat_food"):
		return

	if event.is_echo():
		return

	_try_eat_food()
```

Then add:

```
func _try_eat_food() -> void:
	if game_finished:
		return

	if not day_cycle.running:
		return

	if current_hunger >= maximum_hunger_for_eating:
		_play_ui_denied()

		hud.show_resource_gain(
			"You are not hungry enough",
			_get_player_screen_position()
		)

		return

	var food_type := ResourceTypes.Type.FOOD

	if not backpack.remove_resource(
		food_type,
		1
	):
		_play_ui_denied()

		hud.show_resource_gain(
			"No Food in backpack",
			_get_player_screen_position()
		)

		return

	current_hunger = minf(
		current_hunger + food_hunger_restoration,
		maximum_hunger
	)

	hud.set_hunger(
		current_hunger,
		maximum_hunger
	)

	_reset_hunger_warnings()

	hud.show_resource_gain(
		"+%d Hunger" % roundi(
			food_hunger_restoration
		),
		_get_player_screen_position()
	)

	_play_ui_click()
```

Add:

```
func _reset_hunger_warnings() -> void:
	var hunger_ratio := (
		current_hunger / maximum_hunger
	)

	if hunger_ratio > 0.60:
		low_hunger_warning_shown = false

	if hunger_ratio > 0.30:
		critical_hunger_warning_shown = false
```

## Phase 9 — Remove nightly food consumption

The old `_on_day_ended()` would make food disappear in addition to hunger decreasing.

Replace it with:

```
func _on_day_ended(_day: int) -> void:
	if game_finished:
		return

	# Food is now consumed manually through the hunger system.
```

We can remove the signal connection entirely later, but keeping this empty handler is safe while we develop the rest of the system.

## First test

Run the game and verify:

- Hunger begins at `100`.
- It decreases by approximately one point per second.
- It stops while the camp menu is open.
- It stops when the game is paused.
- Pressing `F` above `85` does not consume food.
- Pressing `F` below `85` consumes one carried food.
- Hunger increases by `80`, capped at `100`.
- Backpack weight decreases by `1`.
- A warning appears at `60%`.
- A critical warning appears at `30%`.
- Reaching zero produces the starvation defeat.
- No food is automatically consumed at the end of the day.

For testing, temporarily set:

```
hunger_decrease_per_second = 10.0
```

Once every state works, return it to:

```
hunger_decrease_per_second = 1.0
```

The next step will add eating from camp storage and update the tutorial so players discover the mechanic naturally.