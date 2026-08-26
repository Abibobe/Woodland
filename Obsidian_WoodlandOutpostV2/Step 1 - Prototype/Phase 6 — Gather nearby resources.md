
Now we’ll add interaction without placing it inside `player.gd`. Movement and interaction will remain separate systems.
### 1. Add the interaction input

Open:

**Project → Project Settings → Input Map**

Create:

```
interact
```

Assign the **E** key.

### 2. Add an interaction area

Open:

```
res://scenes/player/player.tscn
```

Add an `Area2D` under `Player` and name it:

```
PlayerInteraction
```

Add a `CollisionShape2D` beneath it:

```
Player
├── PlayerVisual
├── CollisionShape2D
└── PlayerInteraction (Area2D)
    └── CollisionShape2D
```

For the new collision shape:

1. Create a `CircleShape2D`.
2. Set its radius to `42`.

This circle represents how close the player must be to gather something.

### 3. Create the interaction script

Attach a script to `PlayerInteraction`:

```
res://scripts/player/player_interaction.gd
```

Add:

```
class_name PlayerInteraction
extends Area2D


signal resource_collected(
	resource_type: int,
	amount: int
)


var nearby_resources: Array[ResourceNode] = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact()


func interact() -> void:
	var resource := _get_closest_resource()

	if resource == null:
		return

	var collected_amount := resource.gather(1)

	if collected_amount <= 0:
		return

	resource_collected.emit(
		resource.resource_type,
		collected_amount
	)

	print(
		"Collected ",
		collected_amount,
		" ",
		resource.get_resource_name()
	)


func _get_closest_resource() -> ResourceNode:
	var closest_resource: ResourceNode = null
	var closest_distance := INF

	for resource in nearby_resources:
		if not is_instance_valid(resource):
			continue

		var distance := global_position.distance_to(
			resource.global_position
		)

		if distance < closest_distance:
			closest_distance = distance
			closest_resource = resource

	return closest_resource


func _on_body_entered(body: Node2D) -> void:
	if body is ResourceNode:
		nearby_resources.append(body)


func _on_body_exited(body: Node2D) -> void:
	if body is ResourceNode:
		nearby_resources.erase(body)
```

Notice that this script detects resources and processes interaction, but it does not move the player or store inventory.

## 4. Give resources a gathering function

Open:

```
res://scripts/resources/resource_node.gd
```

Add this function below `get_resource_name()`:

```
func gather(requested_amount: int = 1) -> int:
	if requested_amount <= 0:
		return 0

	var gathered_amount := mini(
		requested_amount,
		resource_amount
	)

	resource_amount -= gathered_amount

	if resource_amount <= 0:
		queue_free()

	return gathered_amount
```

The relevant section should now appear in this order:

```
func get_resource_name() -> String:
	match resource_type:
		ResourceType.WOOD:
			return "Wood"

		ResourceType.STONE:
			return "Stone"

		ResourceType.FOOD:
			return "Food"

	return "Unknown"


func gather(requested_amount: int = 1) -> int:
	if requested_amount <= 0:
		return 0

	var gathered_amount := mini(
		requested_amount,
		resource_amount
	)

	resource_amount -= gathered_amount

	if resource_amount <= 0:
		queue_free()

	return gathered_amount
```

## 5. Test it

Run the game and:

1. Walk close to a resource.
2. Press **E**.
3. Watch the **Output** panel in the Godot editor.

You should see messages such as:

```
Collected 1 Wood
Collected 1 Stone
Collected 1 Food
```

Each resource currently contains three units, so it should disappear after three interactions.

If nothing happens, select `PlayerInteraction` and verify:

- **Monitoring** is enabled.
- Its **Collision Mask** includes layer 1.
- The circular collision shape is not disabled.

We now have another clean separation:

- `player.gd`: movement
- `player_interaction.gd`: detects and activates nearby resources
- `resource_node.gd`: controls an individual resource’s remaining amount

Next, we can create the inventory as a completely independent component and connect it to the `resource_collected` signal.