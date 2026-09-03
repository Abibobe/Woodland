Before adding polish, this is the right moment for a cleanup checkpoint, exactly to prevent losing control of the code again.

Currently many systems depend on:

```
ResourceNode.ResourceType.WOOD
```

But inventory and UI shouldn’t depend on a world object. We’ll create a shared resource definition.

### 1. Create `resource_types.gd`

Create:

```
res://scripts/resources/resource_types.gd
```

Add:

```
class_name ResourceTypes
extends RefCounted


enum Type {
	WOOD,
	STONE,
	FOOD
}


static func get_display_name(
	resource_type: Type
) -> String:
	match resource_type:
		Type.WOOD:
			return "Wood"

		Type.STONE:
			return "Stone"

		Type.FOOD:
			return "Food"

	return "Unknown"
```

### 2. Update `resource_node.gd`

Remove its existing `ResourceType` enum.

Change the exported property to:

```
@export var resource_type: ResourceTypes.Type = ResourceTypes.Type.WOOD:
	set(value):
		resource_type = value
		queue_redraw()
```

Replace `get_resource_name()` with:

```
func get_resource_name() -> String:
	return ResourceTypes.get_display_name(
		resource_type
	)
```

Update `_draw()`:

```
func _draw() -> void:
	match resource_type:
		ResourceTypes.Type.WOOD:
			_draw_tree()

		ResourceTypes.Type.STONE:
			_draw_rock()

		ResourceTypes.Type.FOOD:
			_draw_berry_bush()
```

### 3. Replace old references

Across the project, replace:

```
ResourceNode.ResourceType.WOOD
ResourceNode.ResourceType.STONE
ResourceNode.ResourceType.FOOD
```

with:

```
ResourceTypes.Type.WOOD
ResourceTypes.Type.STONE
ResourceTypes.Type.FOOD
```

The affected scripts should be:

```
resource_spawner.gd
resource_inventory.gd
hud.gd
camp.gd
game_manager.gd
```

Godot’s script editor has **Search → Replace in Files**, which is useful here.

### 4. Simplify `game_manager.gd`

Inside `_format_cost()`, replace:

```
var resource_name := _get_resource_name(
	int(resource_type)
)
```

with:

```
var resource_name := ResourceTypes.get_display_name(
	int(resource_type)
)
```

Then delete the entire `_get_resource_name()` function from `game_manager.gd`.

### 5. Test the complete loop again

Verify:

- Resources spawn correctly.
- Each resource retains its correct type.
- Gathering updates the correct HUD value.
- Camp costs display correctly.
- Food is consumed at the end of a day.
- Victory and defeat still work.

Nothing should change visually. The architectural improvement is that shared resource knowledge now has a proper owner:

```
ResourceTypes
├── ResourceNode
├── ResourceSpawner
├── ResourceInventory
├── Camp
├── HUD
└── GameManager
```

This is the kind of small, controlled refactor we should keep doing between feature phases.