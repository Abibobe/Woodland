I calculated the exact requirements from your scripts:

|Resource|Required|With 50% safety|Nodes needed at 3 units each|
|---|---|---|---|
|Wood|35|53|18 trees|
|Stone|15|23|8 rocks|
|Food|7|11|4 bushes|

Food requires seven units because `day_ended` is emitted on every day, including day 7.

### 1. Reduce resource abundance

In `resource_spawner.gd`, change the default counts to:

```
@export_category("Resource Counts")
@export_range(0, 200) var tree_count: int = 28
@export_range(0, 100) var rock_count: int = 10
@export_range(0, 100) var bush_count: int = 8
```

If `game.tscn` already overrides these values, also change them on the `Spawner` node in the Inspector.

### 2. Add the guarantee configuration

Below the resource counts, add:

```
@export_category("Winnability Guarantees")
@export_range(1, 100) var required_wood := 35
@export_range(1, 100) var required_stone := 15
@export_range(1, 100) var required_food := 7

@export_range(1.0, 3.0, 0.1) var safety_multiplier := 1.5
@export_range(1, 10) var units_per_resource := 3
```

These required values match the current camp costs and seven-day survival period.

### 3. Calculate the guaranteed node count

Add:

```
func _get_guaranteed_node_count(
	required_amount: int
) -> int:
	var safe_amount := ceili(
		required_amount * safety_multiplier
	)

	return ceili(
		float(safe_amount) / float(units_per_resource)
	)
```

### 4. Update `generate_resources()`

After `map_center` is created, add:

```
var final_tree_count := maxi(
	tree_count,
	_get_guaranteed_node_count(required_wood)
)

var final_rock_count := maxi(
	rock_count,
	_get_guaranteed_node_count(required_stone)
)

var final_bush_count := maxi(
	bush_count,
	_get_guaranteed_node_count(required_food)
)
```

Then update the nearby calculations:

```
var guaranteed_trees := mini(
	nearby_tree_count,
	final_tree_count
)

var guaranteed_bushes := mini(
	nearby_bush_count,
	final_bush_count
)
```

In the remaining-tree call, change:

```
tree_count - guaranteed_trees
```

to:

```
final_tree_count - guaranteed_trees
```

In the remaining-bush call, change:

```
bush_count - guaranteed_bushes
```

to:

```
final_bush_count - guaranteed_bushes
```

In the stone call, change:

```
rock_count
```

to:

```
final_rock_count
```

### 5. Make node contents consistent

In `_spawn_resource()`, immediately after:

```
resource.resource_type = resource_type
```

add:

```
resource.resource_amount = units_per_resource
```

This ensures the guarantee calculation and actual resource contents always agree.

### Result

With the suggested counts, each generated map contains:

```
28 trees  = 84 Wood
10 rocks  = 30 Stone
8 bushes  = 24 Food
```

Even if the Inspector count is accidentally set too low, the generator automatically raises it to at least:

```
18 trees
8 rocks
4 bushes
```

The map is therefore scarcer than before but still contains at least 150% of the resources required for victory. The next step is preventing dense resource walls and keeping important resources physically accessible.