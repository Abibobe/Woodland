

First, a small layout correction: the tutorial at `y = 62` would overlap the milestone banner, which begins at `y = 76`.

In `_apply_layout()`, use:

```
tutorial_hint.position = Vector2(
	(viewport_size.x - tutorial_hint.size.x) / 2.0,
	154.0
)
```

## 1. Reference the main menu

In `game_manager.gd`, add:

```
@onready var main_menu: MainMenu = (
	$Interface/MainMenu
)
```

## 2. Define the tutorial states

Near the top of `game_manager.gd`, add:

```
enum TutorialStep {
	WAITING,
	MOVEMENT,
	GATHERING,
	BACKPACK,
	RETURN_TO_CAMP,
	CONSTRUCTION,
	COMPLETE
}
```

Near the other state variables, add:

```
@export_category("Tutorial")
@export var tutorial_enabled := true
@export_range(8.0, 128.0, 1.0) var tutorial_movement_distance := 48.0
@export_range(1, 12, 1) var tutorial_return_weight := 6

var tutorial_step := TutorialStep.WAITING
var tutorial_start_position := Vector2.ZERO
```

The return instruction will appear at 6 kg—half of the backpack’s capacity.

## 3. Detect the start of gameplay

Inside `_ready()`, add:

```
main_menu.visibility_changed.connect(
	_on_main_menu_visibility_changed
)
```

Then add:

```
func _on_main_menu_visibility_changed() -> void:
	if main_menu.visible:
		return

	if not tutorial_enabled:
		return

	if tutorial_step != TutorialStep.WAITING:
		return

	tutorial_start_position = player.global_position

	_set_tutorial_step(
		TutorialStep.MOVEMENT
	)
```

The tutorial now begins only after the main menu disappears.

## 4. Add the tutorial state function

```
func _set_tutorial_step(
	new_step: TutorialStep
) -> void:
	tutorial_step = new_step

	match tutorial_step:
		TutorialStep.MOVEMENT:
			hud.show_tutorial_hint(
				"Use WASD or the arrow keys to explore."
			)

		TutorialStep.GATHERING:
			hud.show_tutorial_hint(
				"Approach a resource and hold E to gather."
			)

		TutorialStep.BACKPACK:
			hud.show_tutorial_hint(
				"Resources have weight. Your backpack can carry 12 kg."
			)

		TutorialStep.RETURN_TO_CAMP:
			hud.show_tutorial_hint(
				"Your backpack is getting heavy. Return to camp."
			)

		TutorialStep.CONSTRUCTION:
			hud.show_tutorial_hint(
				"Use deposited resources to build the cabin before winter."
			)

		TutorialStep.COMPLETE:
			hud.hide_tutorial_hint()
```

## 5. Detect player movement

Add this `_process()` function to `game_manager.gd`:

```
func _process(_delta: float) -> void:
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

After moving 48 pixels, the movement instruction is replaced by the gathering instruction.

## 6. Detect the first successful collection

Inside `_on_interaction_completed()`, find this successful section:

```
if not resource_added:
	push_warning(
		"Backpack capacity changed during collection."
	)
	return
```

Immediately after it, add:

```
if tutorial_step == TutorialStep.GATHERING:
	_set_tutorial_step(
		TutorialStep.BACKPACK
	)
```

This advances only after an item enters the backpack—not merely when gathering begins.

## 7. Detect a sufficiently loaded backpack

At the end of `_on_backpack_weight_changed()`, add:

```
if (
	tutorial_step == TutorialStep.BACKPACK
	and current_weight >= tutorial_return_weight
):
	_set_tutorial_step(
		TutorialStep.RETURN_TO_CAMP
	)
```

The complete function becomes:

```
func _on_backpack_weight_changed(
	current_weight: int,
	maximum_weight: int
) -> void:
	hud.set_backpack_weight(
		current_weight,
		maximum_weight
	)

	if (
		tutorial_step == TutorialStep.BACKPACK
		and current_weight >= tutorial_return_weight
	):
		_set_tutorial_step(
			TutorialStep.RETURN_TO_CAMP
		)
```

## 8. Detect the first delivery

Inside `_on_deposit_timer_timeout()`, immediately after:

```
hud.show_delivery_summary(
	delivered_resources
)
```

add:

```
if (
	tutorial_step == TutorialStep.BACKPACK
	or tutorial_step == TutorialStep.RETURN_TO_CAMP
):
	_set_tutorial_step(
		TutorialStep.CONSTRUCTION
	)
```

This also handles a player returning early with less than 6 kg.

## 9. Complete the tutorial after construction

Inside `_on_camp_build_requested()`, immediately after:

```
active_camp.advance_construction()
```

add:

```
if tutorial_step == TutorialStep.CONSTRUCTION:
	_set_tutorial_step(
		TutorialStep.COMPLETE
	)
```

## Test sequence

Start a new game and verify:

1. Main menu remains clean.
2. Pressing **Start Game** shows the movement hint.
3. Moving approximately 48 pixels shows the gathering hint.
4. Successfully collecting one resource explains backpack weight.
5. Reaching 6 kg asks the player to return.
6. Depositing early or at 6 kg shows the construction objective.
7. Building the first camp stage hides the tutorial permanently for that playthrough.