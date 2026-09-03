Following the roadmap, this first step is deliberately data-only: we’ll create the backpack without connecting it to gathering yet. The released gameplay should continue working exactly as before.

Create:

```
res://scripts/player/player_backpack.gd
```

Add:

```
class_name PlayerBackpack
extends Node


signal contents_changed
signal backpack_full(resource_type: StringName)


const RESOURCE_WEIGHTS := {
	&"wood": 2,
	&"stone": 3,
	&"food": 1
}


@export_range(1, 100, 1)
var maximum_weight: int = 12


var carried_resources: Dictionary = {
	&"wood": 0,
	&"stone": 0,
	&"food": 0
}


func get_current_weight() -> int:
	var total_weight := 0

	for resource_type: StringName in carried_resources:
		var amount: int = carried_resources[resource_type]
		var resource_weight := get_resource_weight(
			resource_type
		)

		total_weight += amount * resource_weight

	return total_weight


func get_available_weight() -> int:
	return maximum_weight - get_current_weight()


func get_resource_weight(
	resource_type: StringName
) -> int:
	var normalized_type := _normalize_resource_type(
		resource_type
	)

	return int(
		RESOURCE_WEIGHTS.get(
			normalized_type,
			0
		)
	)


func can_add(
	resource_type: StringName,
	amount: int = 1
) -> bool:
	if amount <= 0:
		return false

	var resource_weight := get_resource_weight(
		resource_type
	)

	if resource_weight <= 0:
		push_warning(
			"Unknown backpack resource: %s"
			% resource_type
		)
		return false

	var added_weight := resource_weight * amount

	return (
		get_current_weight() + added_weight
		<= maximum_weight
	)


func add_resource(
	resource_type: StringName,
	amount: int = 1
) -> bool:
	var normalized_type := _normalize_resource_type(
		resource_type
	)

	if not can_add(normalized_type, amount):
		backpack_full.emit(normalized_type)
		return false

	var current_amount := get_amount(
		normalized_type
	)

	carried_resources[normalized_type] = (
		current_amount + amount
	)

	contents_changed.emit()
	return true


func get_amount(
	resource_type: StringName
) -> int:
	var normalized_type := _normalize_resource_type(
		resource_type
	)

	return int(
		carried_resources.get(
			normalized_type,
			0
		)
	)


func is_empty() -> bool:
	for amount: int in carried_resources.values():
		if amount > 0:
			return false

	return true


func take_all() -> Dictionary:
	var delivered_resources := (
		carried_resources.duplicate()
	)

	for resource_type: StringName in carried_resources:
		carried_resources[resource_type] = 0

	contents_changed.emit()

	return delivered_resources


func _normalize_resource_type(
	resource_type: StringName
) -> StringName:
	return StringName(
		String(resource_type).to_lower()
	)
```

## Add it to `game.tscn`

Add a regular `Node` beneath `Game`:

```
Game
├── World
├── Entities
├── ResourceInventory
├── PlayerBackpack
├── DayCycle
└── Interface
```

Attach `player_backpack.gd` to `PlayerBackpack`.

In the Inspector, verify:

```
Maximum Weight: 12
```

## What this gives us

The backpack now supports:

- Wood weighing `2`
- Stone weighing `3`
- Food weighing `1`
- Shared capacity of `12`
- Capacity validation
- Full-backpack notification
- Carried-resource counts
- Atomic removal of everything for future camp deposits
- Case-insensitive names such as `"Wood"` and `"wood"`

Nothing uses it yet, so gathering, construction, food consumption, and the HUD should behave exactly as before.

Run the game once and confirm there are no script errors. Then send me the current `resource_inventory.gd` and `game_manager.gd`; we’ll connect the backpack without confusing carried supplies with camp storage.