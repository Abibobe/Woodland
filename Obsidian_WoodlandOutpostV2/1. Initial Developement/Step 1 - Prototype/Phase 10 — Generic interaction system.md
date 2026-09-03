Before adding the camp, we should make one small architectural improvement. Otherwise `PlayerInteraction` would eventually contain separate code for trees, rocks, bushes, camps, doors, and everything else.

### 1. Create an interactions folder

Create:

```
res://scripts/interactions/
```

Inside it, create:

```
interaction_target.gd
```

Add:

```
class_name InteractionTarget
extends StaticBody2D


func get_interaction_text() -> String:
	return "E — Interact"


func interact() -> Dictionary:
	return {}
```

This defines the two things every interactable object must provide:

- The prompt it wants to display.
- What happens when it is activated.

## 2. Make resources interactable

Open `resource_node.gd`.

Change:

```
extends StaticBody2D
```

to:

```
extends InteractionTarget
```

Below `get_resource_name()`, add:

```
func get_interaction_text() -> String:
	return "E — Gather %s" % get_resource_name()


func interact() -> Dictionary:
	var gathered_amount := gather(1)

	if gathered_amount <= 0:
		return {}

	return {
		"action": "resource_collected",
		"resource_type": resource_type,
		"amount": gathered_amount
	}
```

`ResourceNode` still owns gathering, but now it follows the common interaction contract.

## 3. Replace `player_interaction.gd`

Replace the complete contents with:

```
class_name PlayerInteraction
extends Area2D


signal interaction_completed(result: Dictionary)
signal interaction_prompt_changed(text: String)


var nearby_targets: Array[InteractionTarget] = []


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		interact()


func interact() -> void:
	var target := _get_closest_target()

	if target == null:
		return

	var result := target.interact()

	if not result.is_empty():
		interaction_completed.emit(result)

	if target.is_queued_for_deletion():
		nearby_targets.erase(target)

	_refresh_interaction_prompt()


func _get_closest_target() -> InteractionTarget:
	var closest_target: InteractionTarget = null
	var closest_distance := INF

	for target in nearby_targets:
		if not is_instance_valid(target):
			continue

		if target.is_queued_for_deletion():
			continue

		var distance := global_position.distance_to(
			target.global_position
		)

		if distance < closest_distance:
			closest_distance = distance
			closest_target = target

	return closest_target


func _on_body_entered(body: Node2D) -> void:
	if body is InteractionTarget:
		if not nearby_targets.has(body):
			nearby_targets.append(body)

		_refresh_interaction_prompt()


func _on_body_exited(body: Node2D) -> void:
	if body is InteractionTarget:
		nearby_targets.erase(body)
		_refresh_interaction_prompt()


func _refresh_interaction_prompt() -> void:
	var target := _get_closest_target()

	if target == null:
		interaction_prompt_changed.emit("")
		return

	interaction_prompt_changed.emit(
		target.get_interaction_text()
	)
```

Now this script contains no references to resources, camps, or buildings. It only understands generic interaction targets.

## 4. Update `game_manager.gd`

Inside `_ready()`, replace:

```
	player_interaction.resource_collected.connect(
		_on_resource_collected
	)
```

with:

```
	player_interaction.interaction_completed.connect(
		_on_interaction_completed
	)
```

Remove the old `_on_resource_collected()` function and replace it with:

```
func _on_interaction_completed(
	result: Dictionary
) -> void:
	var action: String = result.get(
		"action",
		""
	)

	match action:
		"resource_collected":
			var resource_type := int(
				result.get("resource_type", -1)
			)

			var amount := int(
				result.get("amount", 0)
			)

			inventory.add_resource(
				resource_type,
				amount
			)

		_:
			push_warning(
				"Unknown interaction action: %s"
				% action
			)
```

The prompt connection remains unchanged:

```
	player_interaction.interaction_prompt_changed.connect(
		_on_interaction_prompt_changed
	)
```

## 5. Test the refactor

Run the game and verify:

- The prompt appears near resources.
- Pressing E collects one unit.
- The HUD updates.
- Resources disappear after three collections.

The game should behave exactly as before. The improvement is internal:

```
PlayerInteraction
       ↓
InteractionTarget
       ├── ResourceNode
       ├── Camp
       └── Future objects
```

This is a good example of controlled refactoring: we reorganized the code before adding complexity, while the project was still small. Next, the camp can plug into this system without adding camp-specific code to the player.