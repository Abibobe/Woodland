This phase only tests positioning and collision detection. The existing camp remains unchanged.

### 1. Add the build input

Open:

```
Project → Project Settings → Input Map
```

Create:

```
toggle_build_mode
```

Assign the `B` key.

### 2. Create the placement controller

Create:

```
res://scripts/buildings/camp_placement_controller.gd
```

Add:

```
class_name CampPlacementController
extends Node2D


signal placement_confirmed(
	world_position: Vector2
)


@export_category("References")
@export var player: CharacterBody2D
@export var existing_camp: StaticBody2D

@export_category("World")
@export var world_size := Vector2(
	2304.0,
	1408.0
)

@export_range(8, 128, 1)
var tile_size := 32

@export_range(0.0, 256.0, 1.0)
var world_margin := 64.0


const CAMP_SHAPE_SIZE := Vector2(
	64.0,
	48.0
)

const CAMP_SHAPE_OFFSET := Vector2(
	0.0,
	-8.0
)

const VALID_COLOR := Color(
	0.35,
	0.85,
	0.45,
	0.35
)

const INVALID_COLOR := Color(
	0.95,
	0.30,
	0.28,
	0.38
)

const VALID_BORDER := Color("#8fe18f")
const INVALID_BORDER := Color("#f07872")


var placement_active := false
var placement_valid := false

var query_shape := RectangleShape2D.new()


func _ready() -> void:
	z_index = 100
	texture_filter = (
		CanvasItem.TEXTURE_FILTER_NEAREST
	)

	query_shape.size = CAMP_SHAPE_SIZE

	hide()
	set_process(false)


func begin_placement() -> void:
	placement_active = true

	show()
	set_process(true)

	_update_preview_position()
	_update_placement_validity()
	queue_redraw()


func cancel_placement() -> void:
	placement_active = false

	hide()
	set_process(false)


func _process(_delta: float) -> void:
	if not placement_active:
		return

	_update_preview_position()
	_update_placement_validity()
	queue_redraw()


func _unhandled_input(
	event: InputEvent
) -> void:
	if event.is_echo():
		return

	if event.is_action_pressed(
		"toggle_build_mode"
	):
		if placement_active:
			cancel_placement()
		else:
			begin_placement()

		get_viewport().set_input_as_handled()
		return

	if not placement_active:
		return

	if event.is_action_pressed("ui_cancel"):
		cancel_placement()
		get_viewport().set_input_as_handled()
		return

	if not event is InputEventMouseButton:
		return

	var mouse_event := (
		event as InputEventMouseButton
	)

	if (
		mouse_event.button_index
		!= MOUSE_BUTTON_LEFT
	):
		return

	if not mouse_event.pressed:
		return

	if not placement_valid:
		return

	placement_confirmed.emit(
		global_position
	)

	print(
		"Valid camp position: ",
		global_position
	)

	cancel_placement()
	get_viewport().set_input_as_handled()


func _update_preview_position() -> void:
	var mouse_world_position := (
		get_global_mouse_position()
	)

	global_position = Vector2(
		roundf(
			mouse_world_position.x
			/ float(tile_size)
		) * tile_size,
		roundf(
			mouse_world_position.y
			/ float(tile_size)
		) * tile_size
	)


func _update_placement_validity() -> void:
	placement_valid = (
		_is_inside_world()
		and not _overlaps_obstacle()
	)


func _is_inside_world() -> bool:
	var camp_rect := Rect2(
		global_position
			+ CAMP_SHAPE_OFFSET
			- CAMP_SHAPE_SIZE / 2.0,
		CAMP_SHAPE_SIZE
	)

	var permitted_world := Rect2(
		Vector2(
			world_margin,
			world_margin
		),
		world_size - Vector2.ONE
			* world_margin * 2.0
	)

	return (
		permitted_world.encloses(
			camp_rect
		)
	)


func _overlaps_obstacle() -> bool:
	var world := get_world_2d()

	if world == null:
		return true

	var query := (
		PhysicsShapeQueryParameters2D.new()
	)

	query.shape = query_shape

	query.transform = Transform2D(
		0.0,
		global_position + CAMP_SHAPE_OFFSET
	)

	query.collide_with_bodies = true
	query.collide_with_areas = false
	query.collision_mask = 0xFFFFFFFF

	var exclusions: Array[RID] = []

	if is_instance_valid(player):
		exclusions.append(
			player.get_rid()
		)

	if is_instance_valid(existing_camp):
		exclusions.append(
			existing_camp.get_rid()
		)

	query.exclude = exclusions

	var collisions := (
		world.direct_space_state
		.intersect_shape(
			query,
			1
		)
	)

	return not collisions.is_empty()


func _draw() -> void:
	if not placement_active:
		return

	var preview_rect := Rect2(
		CAMP_SHAPE_OFFSET
			- CAMP_SHAPE_SIZE / 2.0,
		CAMP_SHAPE_SIZE
	)

	var fill_color := (
		VALID_COLOR
		if placement_valid
		else INVALID_COLOR
	)

	var border_color := (
		VALID_BORDER
		if placement_valid
		else INVALID_BORDER
	)

	draw_rect(
		preview_rect,
		fill_color,
		true
	)

	draw_rect(
		preview_rect,
		border_color,
		false,
		2.0
	)

	draw_dashed_line(
		Vector2(-30.0, -24.0),
		Vector2(30.0, -24.0),
		border_color,
		2.0,
		4.0
	)

	draw_dashed_line(
		Vector2(30.0, -24.0),
		Vector2(30.0, 16.0),
		border_color,
		2.0,
		4.0
	)

	draw_dashed_line(
		Vector2(30.0, 16.0),
		Vector2(-30.0, 16.0),
		border_color,
		2.0,
		4.0
	)

	draw_dashed_line(
		Vector2(-30.0, 16.0),
		Vector2(-30.0, -24.0),
		border_color,
		2.0,
		4.0
	)
```

### 3. Add the controller to `game.tscn`

Under `Entities`, add:

```
Entities
├── Player
├── Camp
└── CampPlacementController  [2D Node]
```

Attach the new script.

Assign:

```
Player        → Entities/Player
Existing Camp → Entities/Camp
World Size    → 2304, 1408
Tile Size     → 32
World Margin  → 64
```

### 4. Test the preview

Run the existing game normally:

- Press `B`: the camp footprint appears.
- Move the mouse: it snaps to the 32-pixel grid.
- Open ground produces a green preview.
- Trees, rocks, bushes, and other collision bodies produce red.
- Map edges produce red.
- Escape or `B` cancels placement.
- Clicking a valid position prints its coordinates and hides the preview.
- The original camp remains unchanged.

This intentionally does not move the real camp yet. Once collision validation behaves correctly across several map areas, we’ll connect the confirmed position to the actual camp and introduce Day 0 scouting.

### ISSUE: the box never become green
### FIX::
The world-boundary check is probably working, but the physics query is detecting something that covers the entire map—most likely a terrain or world collision body because we used:

```
query.collision_mask = 0xFFFFFFFF
```

That checks every physics layer.

## 1. Add a dedicated obstacle mask

Near the other exports, add:

```
@export_flags_2d_physics
var placement_obstacle_mask := 1
```

Then replace:

```
query.collision_mask = 0xFFFFFFFF
```

with:

```
query.collision_mask = placement_obstacle_mask
```

In the Inspector, set `Placement Obstacle Mask` to the layer used by trees, rocks, and bushes. This is probably **Layer 1**, but check a `ResourceNode` collision object to confirm.

## 2. Identify what is blocking placement

Temporarily replace the end of `_overlaps_obstacle()`:

```
return not collisions.is_empty()
```

with:

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

Run the game, enter placement mode, and move over apparently empty ground.

The Output panel will reveal the blocker:

```
Camp placement blocked by: Ground
```

or:

```
Camp placement blocked by: Tree
```

If it continually reports terrain, remove that terrain layer from `Placement Obstacle Mask`.

## 3. Make the validity check easier to debug

Temporarily replace `_update_placement_validity()` with:

```
func _update_placement_validity() -> void:
	var inside_world := _is_inside_world()
	var overlaps_obstacle := (
		_overlaps_obstacle()
	)

	placement_valid = (
		inside_world
		and not overlaps_obstacle
	)
```

You can place breakpoints or print those two values separately if necessary.

The expected result is:

- Empty ground: green.
- Resource collision: red.
- Near map boundary: red.
- Decorative grass and flowers: green, because they have no collision.
- Existing camp: ignored during this prototype.
- Player: ignored.

Once you identify the collider printed on empty ground, tell me its name if the preview still never becomes green.

### Camp placement blocked by: CampPlacementController
### FIX::  the camp placement controller is a 2DNode
