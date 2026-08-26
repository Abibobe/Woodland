Let’s add the inventory now. It will store resources but know nothing about the player, world, or HUD.

### 1. Add the inventory node

Open `game.tscn`.

Add a regular `Node` beneath `Game` and name it:

```
ResourceInventory
```

Your scene tree should be:

```
Game
├── World
│   └── ResourceSpawner
├── Actors
│   └── Player
├── ResourceInventory
└── Interface
```

### 2. Create the inventory script

Attach a script to `ResourceInventory`:

```
res://scripts/game/resource_inventory.gd
```

Add:

```
class_name ResourceInventory
extends Node


signal resource_changed(
	resource_type: int,
	new_amount: int
)


@export_category("Starting Resources")
@export_range(0, 100) var starting_wood: int = 0
@export_range(0, 100) var starting_stone: int = 0
@export_range(0, 100) var starting_food: int = 0


var resources: Dictionary = {}


func _ready() -> void:
	resources = {
		ResourceNode.ResourceType.WOOD: starting_wood,
		ResourceNode.ResourceType.STONE: starting_stone,
		ResourceNode.ResourceType.FOOD: starting_food
	}


func add_resource(
	resource_type: int,
	amount: int
) -> void:
	if amount <= 0:
		return

	var current_amount := get_amount(resource_type)
	var new_amount := current_amount + amount

	resources[resource_type] = new_amount

	resource_changed.emit(
		resource_type,
		new_amount
	)


func get_amount(resource_type: int) -> int:
	return resources.get(resource_type, 0)


func has_resources(
	resource_type: int,
	required_amount: int
) -> bool:
	return get_amount(resource_type) >= required_amount


func remove_resource(
	resource_type: int,
	amount: int
) -> bool:
	if amount <= 0:
		return false

	if not has_resources(resource_type, amount):
		return false

	resources[resource_type] -= amount

	resource_changed.emit(
		resource_type,
		resources[resource_type]
	)

	return true


func get_all_resources() -> Dictionary:
	return resources.duplicate()
```

Although we currently only add resources, `has_resources()` and `remove_resource()` will later allow the camp to pay construction costs.

## 3. Create the game coordinator

Select the root `Game` node and attach:

```
res://scripts/game/game_manager.gd
```

Add:

```
class_name GameManager
extends Node2D


@onready var inventory: ResourceInventory = $ResourceInventory

@onready var player_interaction: PlayerInteraction = (
	$Actors/Player/PlayerInteraction
)


func _ready() -> void:
	player_interaction.resource_collected.connect(
		_on_resource_collected
	)

	inventory.resource_changed.connect(
		_on_inventory_resource_changed
	)


func _on_resource_collected(
	resource_type: int,
	amount: int
) -> void:
	inventory.add_resource(
		resource_type,
		amount
	)


func _on_inventory_resource_changed(
	_resource_type: int,
	_new_amount: int
) -> void:
	print(
		"Inventory: ",
		inventory.get_all_resources()
	)
```

`GameManager` coordinates the two independent systems:

```
PlayerInteraction
        ↓ resource_collected
GameManager
        ↓ add_resource()
ResourceInventory
        ↓ resource_changed
HUD later
```

The player interaction does not need to know where the inventory is located, and the inventory does not need to know who gathered the resource.

## 4. Test the inventory

Run the game, approach resources, and press **E**.

In the Output panel, you should see something similar to:

```
Collected 1 Wood
Inventory: {0: 1, 1: 0, 2: 0}
Collected 1 Wood
Inventory: {0: 2, 1: 0, 2: 0}
```

The keys currently mean:

|Number|Resource|
|---|---|
|`0`|Wood|
|`1`|Stone|
|`2`|Food|

The numeric output is temporary. Our minimal HUD will display proper names and values next.