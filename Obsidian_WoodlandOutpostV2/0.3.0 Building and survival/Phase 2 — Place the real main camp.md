For now, placement will be limited to approximately 12 tiles from the starting point. This preserves the existing resource balance, which currently guarantees starter Wood and Food around the map centre.

### 1. Update `CampPlacementController`

Add:

```
@export_range(4, 30, 1)
var maximum_scouting_distance := 12

var scouting_origin := Vector2.ZERO
```

Add a configuration function:

```
func configure(
	new_world_size: Vector2,
	new_scouting_origin: Vector2
) -> void:
	world_size = new_world_size
	scouting_origin = new_scouting_origin
```

Add:

```
func _is_inside_scouting_area() -> bool:
	var maximum_distance_pixels := (
		maximum_scouting_distance
		* float(tile_size)
	)

	return (
		global_position.distance_to(
			scouting_origin
		)
		<= maximum_distance_pixels
	)
```

Then replace `_update_placement_validity()` with:

```
func _update_placement_validity() -> void:
	placement_valid = (
		_is_inside_world()
		and _is_inside_scouting_area()
		and not _overlaps_obstacle()
	)
```

### 2. Allow the camp to be disabled

In `camp.gd`, add:

```
@onready var collision_shape: CollisionShape2D = (
	$CollisionShape2D
)
```

Add:

```
var is_established := true
```

Then add:

```
func set_established(
	established: bool
) -> void:
	is_established = established
	visible = established

	collision_shape.set_deferred(
		"disabled",
		not established
	)

	if not established:
		warm_light.hide()
	else:
		_update_stage_light()
```

Protect the interaction functions:

```
func get_interaction_text() -> String:
	if not is_established:
		return ""

	if current_stage == CampStage.CABIN:
		return "E — Inspect cabin"

	return "E — Inspect camp"
```

Replace `interact()` with:

```
func interact() -> Dictionary:
	if not is_established:
		return {}

	return {
		"action": "camp_opened",
		"camp": self
	}
```

### 3. Update the camp indicator

In `camp_indicator.gd`, inside `_process()`, after validating the camp reference, add:

```
if not camp.visible:
	hide()
	return
```

The indicator will remain hidden before camp placement.

### 4. Reference the placement controller

In `game_manager.gd`, add:

```
@onready var camp_placement_controller: CampPlacementController = (
	$Entities/CampPlacementController
)
```

Add state:

```
var camp_is_placed := false
var scouting_started := false
```

### 5. Configure placement with the world

Inside `_configure_world_layout()`, you currently calculate:

```
var world_center := world_size / 2.0
```

Keep the player at the centre, but remove or comment out:

```
camp.global_position = world_center
```

Replace it with:

```
camp.global_position = world_center

camp_placement_controller.configure(
	world_size,
	world_center
)
```

We temporarily leave the hidden camp at the centre until it is placed.

### 6. Prepare the placement state in `_ready()`

Immediately after `_configure_world_layout()`, add:

```
camp_is_placed = false
scouting_started = false

camp.set_established(false)

camp_placement_controller.set_process_unhandled_input(
	false
)

camp_placement_controller.placement_confirmed.connect(
	_on_camp_placement_confirmed
)
```

The beginning should resemble:

```
func _ready() -> void:
	_configure_world_layout()

	camp_is_placed = false
	scouting_started = false

	camp.set_established(false)

	camp_placement_controller.set_process_unhandled_input(
		false
	)

	camp_placement_controller.placement_confirmed.connect(
		_on_camp_placement_confirmed
	)

	current_hunger = clampf(
```

### 7. Start Day 0 after closing the main menu

Add:

```
func _begin_camp_scouting() -> void:
	if scouting_started:
		return

	scouting_started = true

	day_cycle.set_running(false)

	camp_placement_controller.set_process_unhandled_input(
		true
	)

	hud.set_day(
		0,
		"Scouting"
	)

	hud.show_tutorial_hint(
		"Explore the area, then press B to place your Main Camp."
	)
```

At the beginning of `_on_main_menu_visibility_changed()`, use:

```
func _on_main_menu_visibility_changed() -> void:
	if main_menu.visible:
		return

	if not camp_is_placed:
		_begin_camp_scouting()
		return

	_start_contextual_tutorial()
```

### 8. Extract the existing tutorial-start logic

Create:

```
func _start_contextual_tutorial() -> void:
	if not tutorial_enabled:
		tutorial_step = TutorialStep.COMPLETE
		hud.hide_tutorial_hint()
		return

	if tutorial_step != TutorialStep.WAITING:
		return

	if _was_contextual_tutorial_completed():
		tutorial_step = TutorialStep.COMPLETE
		hud.hide_tutorial_hint()
		return

	tutorial_start_position = player.global_position

	_set_tutorial_step(
		TutorialStep.MOVEMENT
	)
```

Move the equivalent tutorial logic out of the old `_on_main_menu_visibility_changed()` so it is not duplicated.

### 9. Confirm the camp

Add:

```
func _on_camp_placement_confirmed(
	camp_position: Vector2
) -> void:
	if camp_is_placed:
		return

	camp.global_position = camp_position
	camp.set_established(true)

	camp_is_placed = true

	camp_placement_controller.set_process_unhandled_input(
		false
	)

	day_cycle.set_running(true)

	_on_time_display_changed(
		day_cycle.current_day,
		day_cycle.get_phase_name()
	)

	hud.show_milestone(
		"MAIN CAMP ESTABLISHED\nPREPARE FOR WINTER"
	)

	_start_contextual_tutorial()
```

### Test

- The original camp is absent when gameplay begins.
- The HUD reads `Day 0 · Scouting`.
- Hunger and time do not decrease.
- The player can explore normally.
- B activates the placement preview.
- Placement is restricted to 12 tiles from the starting area.
- Trees, rocks, bushes, and map edges block placement.
- Left click places the real camp.
- The camp becomes visible and solid.
- Day 1 and Hunger begin.
- The camp indicator points to the new location.
- E opens camp storage at the placed camp.
- B no longer activates placement after confirmation.

This gives us one real player-selected camp while preserving the current procedural balance.

### ISSUE: click not deploy the camp

The placement controller listens in `_unhandled_input()`. Mouse clicks can be consumed by the full-screen HUD before they reach that stage.

Placement mode should use `_input()`, which receives the click before the UI consumes it.

### 1. Update the controller

In `camp_placement_controller.gd`, rename:

```gdscript
func _unhandled_input(
	event: InputEvent
) -> void:
```

to:

```gdscript
func _input(
	event: InputEvent
) -> void:
```

Keep the function contents unchanged.


### ISSUE: multiple placement after the first
### FIX: ### 1. Add placement availability

Near the existing state variables, add:

```
var placement_available := false
```

Your state should become:

```
var placement_active := false
var placement_valid := false
var placement_available := false
```

### 2. Add enable and lock functions

Add:

```
func enable_placement() -> void:
	placement_available = true
	set_process_input(true)


func lock_placement() -> void:
	placement_available = false
	cancel_placement()
	set_process_input(false)
```

### 3. Protect `begin_placement()`

Replace it with:

```
func begin_placement() -> void:
	if not placement_available:
		return

	placement_active = true

	show()
	set_process(true)

	_update_preview_position()
	_update_placement_validity()
	queue_redraw()
```

### 4. Protect `_input()`

Immediately after the echo check, add:

```
if not placement_available:
	return
```

The beginning becomes:

```
func _input(
	event: InputEvent
) -> void:
	if event.is_echo():
		return

	if not placement_available:
		return

	if event.is_action_pressed(
		"toggle_build_mode"
	):
```

### 5. Consume the Camp Kit before emitting

Replace the successful placement section:

```
placement_confirmed.emit(
	global_position
)

print(
	"Valid camp position: ",
	global_position
)

cancel_placement()
get_viewport().set_input_as_handled()
```

with:

```
var confirmed_position := global_position

# The unique Camp Kit is consumed here, before the
# GameManager receives the placement request.
placement_available = false
cancel_placement()
set_process_input(false)

placement_confirmed.emit(
	confirmed_position
)

get_viewport().set_input_as_handled()
```

### 6. Update `GameManager`

In `_ready()`, replace:

```
camp_placement_controller.set_process_input(
	false
)
```

with:

```
camp_placement_controller.lock_placement()
```

In `_begin_camp_scouting()`, replace:

```
camp_placement_controller.set_process_input(
	true
)
```

with:

```
camp_placement_controller.enable_placement()
```

In `_on_camp_placement_confirmed()`, replace the controller input call with:

```
camp_placement_controller.lock_placement()
```

### 7. Remove the debug spam

Now that collision detection works, replace the diagnostic ending of `_overlaps_obstacle()`:

```
if collisions.is_empty():
	return false

var collider := collisions[0].get(
	"collider"
) as Node

if collider != null:
	print(
		"Camp placement blocked by: ",
		collider.name
	)

return true
```

with:

```
return not collisions.is_empty()
```

After placing the main camp:

- The preview closes.
- The Camp Kit becomes unavailable.
- Input processing for placement stops.
- Pressing B no longer shows another preview.
- `GameManager` still independently prevents duplicate main camps as a second safety check.

Later, when we introduce campfires and traps, B will open the general build menu—but the unique **Main Camp** option will remain permanently disabled.