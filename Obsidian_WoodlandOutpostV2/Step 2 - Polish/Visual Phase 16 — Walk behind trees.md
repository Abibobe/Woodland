Before adding UI icons, there’s an important visual improvement: proper depth sorting.

Currently the player may always appear in front of trees because resources and the player live in different scene branches. We’ll place all world entities beneath one Y-sorted container.

### 1. Reorganize `game.tscn`

Rename:

```
Actors
```

to:

```
Entities
```

Move `Camp` from `World` into `Entities`.

The tree should become:

```
Game
├── World
│   ├── GroundRenderer
│   └── ResourceSpawner
├── Entities
│   ├── Player
│   └── Camp
├── ResourceInventory
├── DayCycle
└── Interface
```

Select `Entities` and enable:

```
Ordering → Y Sort Enabled
```

Moving `Camp` should preserve its position. Confirm it remains:

```
640, 352
```

### 2. Give the spawner a destination

In `resource_spawner.gd`, add:

```
@export_category("Spawn Destination")
@export var resource_parent: Node2D


var spawned_resources: Array[ResourceNode] = []
```

### 3. Update `_spawn_resource()`

Replace:

```
add_child(resource)

resource.position = Vector2(
```

with:

```
var destination := resource_parent

if destination == null:
	destination = self

destination.add_child(resource)
spawned_resources.append(resource)

resource.position = Vector2(
```

### 4. Update resource cleanup

Replace `_clear_existing_resources()` with:

```
func _clear_existing_resources() -> void:
	for resource in spawned_resources:
		if is_instance_valid(resource):
			resource.queue_free()

	spawned_resources.clear()
```

This prevents the spawner from accidentally deleting the player or camp.

### 5. Assign the destination

Select `ResourceSpawner` in `game.tscn`.

Drag the `Entities` node from the scene tree into:

```
Spawn Destination → Resource Parent
```

Resources will now be added as direct children of `Entities`.

### 6. Update `GameManager` paths

Change:

```
@onready var player: Player = $Actors/Player
```

to:

```
@onready var player: Player = $Entities/Player
```

Change:

```
@onready var player_interaction: PlayerInteraction = (
	$Actors/Player/PlayerInteraction
)
```

to:

```
@onready var player_interaction: PlayerInteraction = (
	$Entities/Player/PlayerInteraction
)
```

Change:

```
@onready var camp: Camp = $World/Camp
```

to:

```
@onready var camp: Camp = $Entities/Camp
```

### Fix `GroundRenderer`

Open `ground_renderer.gd` and update `_ready()`:

```
func _ready() -> void:
	z_index = -100
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
```

This permanently places the ground behind all entities.

### 7. Test depth

Run the game and walk:

- Above a tree: the tree crown should cover the player.
- Below a tree: the player should appear in front.
- Around the camp and bushes: their order should also change naturally based on Y position.

Because every sprite’s origin is near its base, Y-sorting should produce convincing top-down depth without extra code.