We’ll require an empty ring around every spawned resource. This prevents trees and rocks from forming solid clusters that trap the player or block access.

### 1. Add the spacing option

In `resource_spawner.gd`, under the distribution exports, add:

```
@export_range(0, 3) var minimum_resource_spacing := 1
```

A value of `1` means no two resources can occupy horizontally, vertically, or diagonally adjacent cells.

### 2. Add the spacing check

Add this function:

```
func _has_required_spacing(
	candidate: Vector2i
) -> bool:
	for offset_y in range(
		-minimum_resource_spacing,
		minimum_resource_spacing + 1
	):
		for offset_x in range(
			-minimum_resource_spacing,
			minimum_resource_spacing + 1
		):
			var nearby_cell := (
				candidate
				+ Vector2i(offset_x, offset_y)
			)

			if occupied_cells.has(nearby_cell):
				return false

	return true
```

### 3. Update `_find_available_cell()`

Find:

```
if occupied_cells.has(candidate):
	continue
```

Replace it with:

```
if not _has_required_spacing(candidate):
	continue
```

Keep this line at the end of the successful placement:

```
occupied_cells[candidate] = true
```

### 4. Increase placement attempts

Because spacing makes valid positions more selective, change:

```
var maximum_attempts := 500
```

to:

```
var maximum_attempts := 2000
```

### Result

Each resource now has accessible ground around it:

```
Empty  Empty  Empty
Empty  Resource  Empty
Empty  Empty  Empty
```

This provides enough room for the player to approach every tree, rock, and bush from multiple directions. It also makes the sparse forest look more intentional and prevents large collision walls.

Test several randomly generated worlds and verify there are no touching resource sprites. The visual crowns may still overlap slightly because trees are wider than their cells, but their collision cells and interaction routes remain separated.