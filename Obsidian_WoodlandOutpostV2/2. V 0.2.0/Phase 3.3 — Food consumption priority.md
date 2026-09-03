Now we’ll complete the camp-storage loop: daily food consumption will use deposited food first, then emergency food from the backpack.

### 1. Update `player_backpack.gd`

Add these functions beneath `get_amount()`:

```
func has_resource(
	resource_type: ResourceTypes.Type,
	amount: int = 1
) -> bool:
	return get_amount(resource_type) >= amount


func remove_resource(
	resource_type: ResourceTypes.Type,
	amount: int = 1
) -> bool:
	if amount <= 0:
		return false

	if not has_resource(resource_type, amount):
		return false

	carried_resources[resource_type] -= amount

	resource_changed.emit(
		resource_type,
		carried_resources[resource_type]
	)

	_emit_weight_changed()

	return true
```

Removing carried food now also updates the backpack weight automatically.

### 2. Update daily consumption

In `game_manager.gd`, find `_on_day_ended()` and replace only its food-consumption section with this logic:

```
func _on_day_ended(day: int) -> void:
	if game_finished:
		return

	var food_type := ResourceTypes.Type.FOOD

	if inventory.remove_resource(food_type, 1):
		print("Consumed 1 Food from camp storage.")
		return

	if backpack.remove_resource(food_type, 1):
		hud.show_resource_gain(
			"-1 Food from backpack",
			_get_player_screen_position()
		)

		print("Consumed 1 Food from backpack.")
		return

	_finish_game(
		"Defeat",
		"Your supplies ran out before the cabin was complete."
	)
```

Important: if your existing function contains winter-deadline logic, preserve it. Only replace the old section that checks and removes daily food.

The intended order should be:

```
func _on_day_ended(day: int) -> void:
	if game_finished:
		return

	# Keep your existing winter/deadline check here.

	var food_type := ResourceTypes.Type.FOOD

	if inventory.remove_resource(food_type, 1):
		return

	if backpack.remove_resource(food_type, 1):
		hud.show_resource_gain(
			"-1 Food from backpack",
			_get_player_screen_position()
		)
		return

	_finish_game(
		"Defeat",
		"Your supplies ran out before the cabin was complete."
	)
```

### 3. Test the three cases

- Camp has food: one deposited Food is consumed.
- Camp has no food, backpack has food: one carried Food is consumed and backpack weight decreases.
- Neither contains food: the defeat screen appears.

This establishes the correct resource priority: construction and normal supplies depend on camp storage, while carried food acts as an emergency reserve.