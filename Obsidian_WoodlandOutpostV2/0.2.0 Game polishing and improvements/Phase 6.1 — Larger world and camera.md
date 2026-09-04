We’ll begin with:

```
72 × 44 tiles
2304 × 1408 pixels
```

### 1. Increase the map dimensions

Open `game.tscn` and select `World`.

In the Inspector, set:

```
Map Width:  72
Map Height: 44
Tile Size:  32
```

Because these are exported properties, setting them on `World` overrides the script defaults.

### 2. Add the player camera

Under `Player`, add a `Camera2D`:

```
Entities
└── Player
    ├── PlayerVisual
    ├── CollisionShape2D
    ├── PlayerInteraction
    └── PlayerCamera
```

Configure it:

```
Enabled: On
Position Smoothing → Enabled: Off
```

We will configure its limits from code so they always match the generated map.

### 3. Add the references to `game_manager.gd`

Near the existing `@onready` variables, add:

```
@onready var world_generator: WorldGenerator = $World

@onready var player_camera: Camera2D = (
	$Entities/Player/PlayerCamera
)
```

### 4. Configure the map layout dynamically

Add this function:

```
func _configure_world_layout() -> void:
	var world_size := Vector2(
		world_generator.map_width
			* world_generator.tile_size,
		world_generator.map_height
			* world_generator.tile_size
	)

	var world_center := world_size / 2.0

	camp.global_position = world_center

	player.global_position = (
		world_center + Vector2(0.0, 88.0)
	)

	player.minimum_position = Vector2(
		10.0,
		14.0
	)

	player.maximum_position = Vector2(
		world_size.x - 10.0,
		world_size.y - 10.0
	)

	player_camera.limit_left = 0
	player_camera.limit_top = 0
	player_camera.limit_right = roundi(world_size.x)
	player_camera.limit_bottom = roundi(world_size.y)
```

This removes the need to manually recalculate the camp, player, boundaries, and camera whenever the map size changes.

### 5. Call it during startup

At the very beginning of `GameManager._ready()`, add:

```
func _ready() -> void:
	_configure_world_layout()

	player_interaction.interaction_completed.connect(
```

Keep everything else in `_ready()` unchanged.

### 6. Test the enlarged world

Run the game and verify:

- The player begins just below the camp.
- The camera follows the player.
- The HUD remains fixed on the screen.
- The player can explore beyond the original screen.
- The camera stops at all four map edges.
- The player cannot leave the generated terrain.
- The camp remains in the middle of the forest.

Resources will currently be distributed uniformly across the larger map. That is expected—the next step will introduce resource distance bands, keeping starter food and wood near camp while moving much of the stone farther away.

### FIX: player can go behind the top bar

That happens because the HUD correctly renders above the world, but the player’s minimum Y boundary still allows them into the HUD’s 42-pixel area.

In `_configure_world_layout()`, replace:

```
player.minimum_position = Vector2(
	10.0,
	14.0
)
```

with:

```
player.minimum_position = Vector2(
	10.0,
	64.0
)
```

The `64` pixels reserve:

- `42` pixels for the top bar.
- Approximately `16` pixels for the upper half of the player sprite.
- A small visual margin.

Keep the camera limits unchanged:

```
player_camera.limit_left = 0
player_camera.limit_top = 0
player_camera.limit_right = roundi(world_size.x)
player_camera.limit_bottom = roundi(world_size.y)
```

Now, at the northern edge of the map, the player should stop cleanly below the HUD instead of walking behind it. Resources already begin several rows from the upper edge, so they should remain visible as well.