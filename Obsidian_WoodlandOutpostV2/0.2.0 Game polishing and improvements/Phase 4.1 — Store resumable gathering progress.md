For now, we’ll only add progress data to each resource. Collection will continue working normally until the next step connects holding `E`.

### 1. Add gathering configuration

In `resource_node.gd`, below the audio exports, add:

```
@export_category("Gathering")
@export_range(0.1, 120.0, 0.1) var food_gather_duration := 2.0
@export_range(0.1, 120.0, 0.1) var wood_gather_duration := 3.0
@export_range(0.1, 120.0, 0.1) var stone_gather_duration := 4.0
```

These are deliberately short testing durations.

### 2. Add the saved progress variable

Near your other state variables, add:

```
var gathering_elapsed := 0.0
```

This belongs to the individual `ResourceNode`, so every tree, rock, and bush remembers its own progress.

### 3. Add the duration function

Add beneath `get_resource_name()`:

```
func get_gathering_duration() -> float:
	match resource_type:
		ResourceTypes.Type.FOOD:
			return food_gather_duration

		ResourceTypes.Type.WOOD:
			return wood_gather_duration

		ResourceTypes.Type.STONE:
			return stone_gather_duration

	return wood_gather_duration
```

### 4. Add the progress functions

Add these beneath `get_gathering_duration()`:

```
func advance_gathering(delta: float) -> bool:
	if is_depleted:
		return false

	gathering_elapsed = minf(
		gathering_elapsed + delta,
		get_gathering_duration()
	)

	return is_gathering_complete()


func is_gathering_complete() -> bool:
	return gathering_elapsed >= get_gathering_duration()


func get_gathering_ratio() -> float:
	return clampf(
		gathering_elapsed / get_gathering_duration(),
		0.0,
		1.0
	)
```

`get_gathering_ratio()` returns a value between `0.0` and `1.0`, which the progress bar will use later.

### 5. Add the completion function

Place this immediately above your existing `collect()` function:

```
func complete_gathering(
	requested_amount: int = 1
) -> int:
	if not is_gathering_complete():
		return 0

	var gathered_amount := collect(
		requested_amount
	)

	if gathered_amount > 0:
		gathering_elapsed = 0.0

	return gathered_amount
```

Notice that progress resets only after successful collection. Therefore, if the backpack is full, we simply avoid calling `complete_gathering()` and the resource remains at 100%.

### 6. Update the interaction text

Replace:

```
func get_interaction_text() -> String:
	return "E — Gather %s" % get_resource_name()
```

with:

```
func get_interaction_text() -> String:
	if gathering_elapsed > 0.0:
		return "Hold E — Resume %s" % get_resource_name()

	return "Hold E — Gather %s" % get_resource_name()
```

Run the project once and ensure there are no script errors. Gameplay will still gather immediately at this stage—that is expected.

Next, we’ll change `PlayerInteraction` so holding `E` advances this stored progress and releasing it stops without resetting anything.