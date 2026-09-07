Replace `_try_eat_food()` in `game_manager.gd` with:

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
	var food_source := ""

	# Carried food can be eaten anywhere.
	if backpack.remove_resource(
		food_type,
		1
	):
		food_source = "backpack"

	# Camp storage can only be used while standing near camp.
	elif (
		player_interaction.has_target(camp)
		and inventory.remove_resource(food_type, 1)
	):
		food_source = "camp"

	if food_source.is_empty():
		_play_ui_denied()

		if player_interaction.has_target(camp):
			hud.show_resource_gain(
				"No Food available",
				_get_player_screen_position()
			)
		else:
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

	var source_text := (
		"Backpack"
		if food_source == "backpack"
		else "Camp storage"
	)

	hud.show_resource_gain(
		"+%d Hunger · %s" % [
			roundi(food_hunger_restoration),
			source_text
		],
		_get_player_screen_position()
	)

	_play_ui_click()
```

The priority is intentional:

1. Use carried food first.
2. If none is carried and the player is near camp, use stored food.
3. Stored food cannot be consumed remotely.

## Allow eating while the camp menu is open

Currently `_try_eat_food()` returns when `day_cycle.running` is false. The camp menu also stops the day cycle, so eating from its storage would be blocked.

Replace:

```
if not day_cycle.running:
	return
```

inside `_try_eat_food()` with:

```
var camp_menu_is_open := (
	is_instance_valid(active_camp)
	and camp_menu.visible
)

if not day_cycle.running and not camp_menu_is_open:
	return
```

Then update the storage condition from:

```
elif (
	player_interaction.has_target(camp)
	and inventory.remove_resource(food_type, 1)
):
```

to:

```
elif (
	(
		player_interaction.has_target(camp)
		or camp_menu_is_open
	)
	and inventory.remove_resource(food_type, 1)
):
```

This lets `F` work while inspecting the camp menu, but hunger remains frozen because the menu is open.

## Improve the interaction message near camp

Inside `_open_camp_menu()`, after:

```
_refresh_camp_menu()
```

add:

```
if current_hunger < maximum_hunger_for_eating:
	camp_menu.show_message(
		"Press F to eat Food from storage"
	)
```

This makes the storage option discoverable.

## Update the How to Play instructions

In `game.tscn`, find the old text:

```
One food is consumed each day.
```

Replace it with:

```
Hunger decreases throughout the day.
Carry Food and press F to eat.
Near camp, you can also eat from storage.
If Hunger reaches zero, the game is lost.
```

If this label becomes too tall, increase its container or label minimum height by approximately `36` pixels.

Also update the controls section from:

```
E — Gather or interact
```

to:

```
E — Gather or interact
F — Eat carried Food
```

## Add an early contextual tutorial hint

The warning at 60 hunger already explains the mechanic, but the first food collection is a better teaching moment.

In `_on_interaction_completed()`, after food has successfully been added to the backpack, add:

```
if (
	resource_type == ResourceTypes.Type.FOOD
	and current_hunger < maximum_hunger_for_eating
):
	hud.show_tutorial_hint(
		"Press F to eat carried Food and restore Hunger."
	)
```

Do not change `tutorial_step` here. Hunger is independent from the existing movement–gathering–backpack tutorial sequence.

To prevent this hint from remaining indefinitely, we can hide it after successful eating. Inside `_try_eat_food()`, after:

```
_reset_hunger_warnings()
```

add:

```
if tutorial_step == TutorialStep.COMPLETE:
	hud.hide_tutorial_hint()
```

## Test

Verify these four situations:

|Situation|Expected result|
|---|---|
|Food in backpack, away from camp|Backpack food is eaten|
|No carried food, away from camp|“No Food in backpack”|
|No carried food, near camp|One stored food is eaten|
|Camp menu open|`F` consumes stored food while hunger remains frozen|

Also confirm the top-bar food counter decreases when camp food is eaten. Your existing `inventory.resource_changed` connection should update it automatically.