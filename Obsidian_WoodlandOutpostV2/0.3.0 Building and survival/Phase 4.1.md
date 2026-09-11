
Perfect—the backpack already provides everything we need. We can now connect real campfire placement without changing its inventory code.

First, we’ll extend the placement controller so it distinguishes the unique main camp from repeatable campfires.

## 1. Add placement types and signals

Near the top of `camp_placement_controller.gd`, add:

```
signal campfire_placement_confirmed(
	world_position: Vector2
)

signal placement_cancelled


enum PlacementType {
	MAIN_CAMP,
	CAMPFIRE
}
```

Add these variables:

```
var current_placement_type := (
	PlacementType.MAIN_CAMP
)

var current_shape_size := CAMP_SHAPE_SIZE
var current_shape_offset := CAMP_SHAPE_OFFSET
```

Add campfire footprint constants:

```
const CAMPFIRE_SHAPE_SIZE := Vector2(
	24.0,
	20.0
)

const CAMPFIRE_SHAPE_OFFSET := Vector2(
	0.0,
	0.0
)
```

## 2. Add the campfire placement function

Keep your existing `begin_placement()` for the main camp, but make it:

```
func begin_placement() -> void:
	if not placement_available:
		return

	current_placement_type = (
		PlacementType.MAIN_CAMP
	)

	current_shape_size = CAMP_SHAPE_SIZE
	current_shape_offset = CAMP_SHAPE_OFFSET
	query_shape.size = current_shape_size

	_start_placement()
```

Then add:

```
func begin_campfire_placement() -> void:
	current_placement_type = (
		PlacementType.CAMPFIRE
	)

	current_shape_size = CAMPFIRE_SHAPE_SIZE
	current_shape_offset = (
		CAMPFIRE_SHAPE_OFFSET
	)

	query_shape.size = current_shape_size

	_start_placement()
```

And add the shared function:

```
func _start_placement() -> void:
	placement_active = true

	show()
	set_process(true)

	_update_preview_position()
	_update_placement_validity()
	queue_redraw()
```

The important detail is that campfires do not use `placement_available`. That variable continues to prevent a second main camp, while campfires remain repeatable.

## 3. Update cancellation

Replace `cancel_placement()` with:

```
func cancel_placement(
	emit_signal: bool = true
) -> void:
	if not placement_active:
		return

	placement_active = false

	hide()
	set_process(false)

	if emit_signal:
		placement_cancelled.emit()
```

## 4. Emit the correct confirmation signal

In `_input()`, replace the current confirmation section:

```
placement_confirmed.emit(
	global_position
)

cancel_placement()
```

with:

```
var confirmed_position := global_position

if (
	current_placement_type
	== PlacementType.MAIN_CAMP
):
	placement_available = false

	cancel_placement(false)

	placement_confirmed.emit(
		confirmed_position
	)
else:
	cancel_placement(false)

	campfire_placement_confirmed.emit(
		confirmed_position
	)

get_viewport().set_input_as_handled()
```

Remove the old `print("Valid camp position...")` if it is still present.

## 5. Make collision checks use the selected footprint

Inside `_overlaps_obstacle()`, replace:

```
global_position + CAMP_SHAPE_OFFSET
```

with:

```
global_position + current_shape_offset
```

Inside `_draw()`, replace the creation of `preview_rect` with:

```
var preview_rect := Rect2(
	current_shape_offset
		- current_shape_size / 2.0,
	current_shape_size
)
```

You can also remove the four hard-coded `draw_dashed_line()` calls. The existing outlined rectangle already adapts properly to both footprints:

```
draw_rect(
	preview_rect,
	border_color,
	false,
	2.0
)
```

## 6. Give campfires a local construction range

Add:

```
@export_range(1, 8, 1)
var maximum_campfire_distance := 4
```

Add:

```
func _is_inside_campfire_range() -> bool:
	if not is_instance_valid(player):
		return false

	var maximum_distance_pixels := (
		maximum_campfire_distance
		* float(tile_size)
	)

	return (
		global_position.distance_to(
			player.global_position
		)
		<= maximum_distance_pixels
	)
```

Replace `_update_placement_validity()` with:

```
func _update_placement_validity() -> void:
	var inside_allowed_area := false

	if (
		current_placement_type
		== PlacementType.MAIN_CAMP
	):
		inside_allowed_area = (
			_is_inside_scouting_area()
		)
	else:
		inside_allowed_area = (
			_is_inside_campfire_range()
		)

	placement_valid = (
		_is_inside_world()
		and inside_allowed_area
		and not _overlaps_obstacle()
	)
```

Also update `_is_inside_world()` to use the current footprint:

```
func _is_inside_world() -> bool:
	var placement_rect := Rect2(
		global_position
			+ current_shape_offset
			- current_shape_size / 2.0,
		current_shape_size
	)

	var permitted_world := Rect2(
		Vector2(
			world_margin,
			world_margin
		),
		world_size
			- Vector2.ONE
			* world_margin
			* 2.0
	)

	return permitted_world.encloses(
		placement_rect
	)
```

## 7. Connect it in `GameManager`

Add an exported scene reference:

```
@export_category("Buildable Structures")
@export var campfire_scene: PackedScene
```

In Godot’s Inspector, assign your `buildable_campfire.tscn` to this field.

In `_ready()`, add:

```
camp_placement_controller.campfire_placement_confirmed.connect(
	_on_campfire_placement_confirmed
)

camp_placement_controller.placement_cancelled.connect(
	_on_structure_placement_cancelled
)
```

Add the Wood cost:

```
const CAMPFIRE_WOOD_COST := 3
```

Replace or create the build-menu handler:

```
func _on_campfire_build_requested() -> void:
	if (
		backpack.get_amount(
			ResourceTypes.Type.WOOD
		)
		< CAMPFIRE_WOOD_COST
	):
		return

	_close_build_menu()

	camp_placement_controller.begin_campfire_placement()
```

Add the confirmation handler:

```
func _on_campfire_placement_confirmed(
	world_position: Vector2
) -> void:
	if campfire_scene == null:
		push_error(
			"Campfire scene has not been assigned."
		)
		return

	if (
		backpack.get_amount(
			ResourceTypes.Type.WOOD
		)
		< CAMPFIRE_WOOD_COST
	):
		return

	var cost_paid := backpack.remove_resource(
		ResourceTypes.Type.WOOD,
		CAMPFIRE_WOOD_COST
	)

	if not cost_paid:
		return

	var new_campfire := (
		campfire_scene.instantiate()
		as Node2D
	)

	if new_campfire == null:
		push_error(
			"Campfire scene root must inherit Node2D."
		)
		return

	var structures_parent := get_node_or_null(
		"../Entities/Structures"
	)

	if structures_parent == null:
		structures_parent = get_node_or_null(
			"../Entities"
		)

	if structures_parent == null:
		push_error(
			"Could not find the Entities node."
		)
		return

	structures_parent.add_child(
		new_campfire
	)

	new_campfire.global_position = (
		world_position
	)

	_update_entire_hud()
```

Depending on where `GameManager` sits in your scene, the `../Entities` paths may be wrong. Since your existing controller reference is:

```
$Entities/CampPlacementController
```

it looks like `GameManager` is probably attached to the game root. In that case use:

```
var structures_parent := get_node_or_null(
	"Entities/Structures"
)

if structures_parent == null:
	structures_parent = $Entities
```

That version is probably the correct one for your scene.

Finally, add:

```
func _on_structure_placement_cancelled() -> void:
	pass
```

No refund is needed because the Wood is only removed after valid placement.

## Test

- Carry fewer than 3 Wood: the Campfire option should do nothing or remain disabled.
- Carry at least 3 Wood and select Campfire.
- A small green/red preview should appear.
- It should only be green within four tiles of the player.
- Left-click green: the fire appears and exactly 3 Wood disappears.
- Left-click red: nothing happens.
- Press `Esc`: placement ends without consuming Wood.
- Open the build menu again: another campfire can be built.
- Pressing `B` must never allow a second main camp.