Good news: `ResourceInventory` is already perfectly suited to become camp storage. Construction and daily food consumption both read from it, so we should leave those paths unchanged.

I did find one important compatibility issue: your project identifies resources with `ResourceTypes.Type` integers, while our first backpack draft used text names. Let’s correct that now before connecting anything.

Replace the complete contents of `player_backpack.gd` with:

```
class_name PlayerBackpack
extends Node


signal resource_changed(
	resource_type: int,
	new_amount: int
)

signal weight_changed(
	current_weight: int,
	maximum_weight: int
)

signal backpack_full(resource_type: int)


const RESOURCE_WEIGHTS := {
	ResourceTypes.Type.WOOD: 2,
	ResourceTypes.Type.STONE: 3,
	ResourceTypes.Type.FOOD: 1
}


@export_range(1, 100, 1)
var maximum_weight: int = 12


var carried_resources: Dictionary = {}


func _ready() -> void:
	carried_resources = {
		ResourceTypes.Type.WOOD: 0,
		ResourceTypes.Type.STONE: 0,
		ResourceTypes.Type.FOOD: 0
	}

	_emit_weight_changed()


func get_current_weight() -> int:
	var total_weight := 0

	for resource_type in carried_resources:
		var amount := get_amount(
			int(resource_type)
		)

		var resource_weight := get_resource_weight(
			int(resource_type)
		)

		total_weight += amount * resource_weight

	return total_weight


func get_available_weight() -> int:
	return maximum_weight - get_current_weight()


func get_resource_weight(
	resource_type: int
) -> int:
	return int(
		RESOURCE_WEIGHTS.get(
			resource_type,
			0
		)
	)


func can_add(
	resource_type: int,
	amount: int = 1
) -> bool:
	if amount <= 0:
		return false

	var resource_weight := get_resource_weight(
		resource_type
	)

	if resource_weight <= 0:
		push_warning(
			"Unknown backpack resource type: %s"
			% resource_type
		)
		return false

	var added_weight := resource_weight * amount

	return (
		get_current_weight() + added_weight
		<= maximum_weight
	)


func add_resource(
	resource_type: int,
	amount: int = 1
) -> bool:
	if not can_add(resource_type, amount):
		backpack_full.emit(resource_type)
		return false

	var new_amount := (
		get_amount(resource_type) + amount
	)

	carried_resources[resource_type] = new_amount

	resource_changed.emit(
		resource_type,
		new_amount
	)

	_emit_weight_changed()
	return true


func get_amount(resource_type: int) -> int:
	return int(
		carried_resources.get(
			resource_type,
			0
		)
	)


func get_all_resources() -> Dictionary:
	return carried_resources.duplicate()


func is_empty() -> bool:
	for amount in carried_resources.values():
		if int(amount) > 0:
			return false

	return true


func take_all() -> Dictionary:
	var delivered_resources := (
		carried_resources.duplicate()
	)

	for resource_type in carried_resources:
		carried_resources[resource_type] = 0

		resource_changed.emit(
			int(resource_type),
			0
		)

	_emit_weight_changed()

	return delivered_resources


func _emit_weight_changed() -> void:
	weight_changed.emit(
		get_current_weight(),
		maximum_weight
	)
```

## Add the GameManager reference

Near the top of `game_manager.gd`, immediately beneath the existing inventory reference, add:

```
@onready var inventory: ResourceInventory = $ResourceInventory
@onready var backpack: PlayerBackpack = $PlayerBackpack
```

Do not change `_on_interaction_completed()` yet. Resources should continue going directly into `ResourceInventory` for this test.

## Why `ResourceInventory` stays unchanged

It already provides everything camp storage needs:

- Adding deposited supplies
- Removing construction costs
- Checking affordability
- Consuming daily food
- Updating stored-resource HUD counters
- Supplying final result statistics

So its existing `resources` dictionary now conceptually means:

```
Resources stored at camp
```

No code change is required there yet.

## Test

Run the game and verify:

- No parser errors.
- Gathering still updates the existing counters.
- Construction still works.
- Daily food consumption still works.
- Victory and defeat still work.

The backpack exists and uses the correct resource identifiers, but it does not affect gameplay yet.

Next, send the current:

- `hud.gd`
- `player_interaction.gd`
- `resource_node.gd`

Then we’ll redirect completed gathering into the backpack, display its weight, and prevent collection when the next item would exceed capacity.